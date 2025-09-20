import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentWebViewPage extends StatefulWidget {
  final String url;
  final String orderId;
  final int totalAmount;

  const PaymentWebViewPage({
    super.key,
    required this.url,
    required this.orderId,
    required this.totalAmount,
  });

  @override
  State<PaymentWebViewPage> createState() => _PaymentWebViewPageState();
}

class _PaymentWebViewPageState extends State<PaymentWebViewPage> {
  late final WebViewController _controller;
  bool _transactionCompleted = false;

  // ShopeePay finish detection
  bool _navigatingToExample = false;

  // GoPay deeplink auto-trigger guard
  bool _triedAutoGopayDeeplink = false;
  bool _isLaunchingDeepLink = false;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (kDebugMode) debugPrint('[SNAP][start] $url');
          },
          onPageFinished: (String url) async {
            if (kDebugMode) debugPrint('[SNAP][done ] $url');
            if (_transactionCompleted) return;

            // AUTO trigger GoPay deeplink dari dalam WebView (tanpa browser)
            if (!_triedAutoGopayDeeplink && _looksLikeGoPayStage(url)) {
              _triedAutoGopayDeeplink = true;
              try {
                await _controller.runJavaScriptReturningResult(r"""
                  (function() {
                    var a = document.querySelector(
                      'a[href^="intent://"], a[href^="gojek://"], a[href^="gopay://"]'
                    );
                    if (a && a.href) { window.location = a.href; return 'ok'; }
                    return 'no-link';
                  })();
                """);
              } catch (_) {}
            }

            // Backup: deteksi teks sukses
            try {
              final html = await _controller.runJavaScriptReturningResult(
                "document.documentElement.outerHTML",
              );
              final htmlString = html.toString().toLowerCase();

              final success = htmlString.contains('transaction is successful') ||
                  htmlString.contains('payment successful') ||
                  htmlString.contains('status: paid') ||
                  htmlString.contains('pembayaran berhasil');

              if (success) {
                _transactionCompleted = true;
                await _handlePaymentSuccess();
              }
            } catch (_) {}
          },
          onNavigationRequest: (NavigationRequest request) async {
            final url = request.url;
            if (kDebugMode) debugPrint('[SNAP][nav ] $url');

            // 1) Deeplink e-wallet → buka langsung APP (tanpa browser)
            if (_isDeepLink(url)) {
              await _launchDeepLinkToAppOnly(url);
              return NavigationDecision.prevent;
            }

            // 2) ShopeePay finish → redirect example.com (cleartext) → anggap sukses
            final host = Uri.tryParse(url)?.host ?? '';
            _navigatingToExample = host == 'example.com';
            if (_navigatingToExample) {
              _transactionCompleted = true;
              await _handlePaymentSuccess();
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) async {
            if (kDebugMode) {
              debugPrint('[SNAP][error] ${error.errorCode} - ${error.description}');
            }
            // ShopeePay: kalau cleartext diblok saat menuju example.com → anggap sukses
            if (!_transactionCompleted &&
                _navigatingToExample &&
                error.description.contains('ERR_CLEARTEXT_NOT_PERMITTED')) {
              _transactionCompleted = true;
              await _handlePaymentSuccess();
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  // ---------------- Helpers ----------------

  // Deteksi halaman GoPay di Snap/Simulator
  bool _looksLikeGoPayStage(String url) {
    final u = Uri.tryParse(url);
    if (u == null) return false;
    final host = u.host.toLowerCase();
    final path = u.path.toLowerCase();
    final frag = u.fragment.toLowerCase();
    return host.contains('midtrans') &&
        (frag.contains('gopay') || path.contains('deeplink'));
  }

  bool _isDeepLink(String url) {
    return url.startsWith('intent://') ||
        url.startsWith('gojek://') ||
        url.startsWith('gopay://') ||
        url.startsWith('ovo://') ||
        url.startsWith('shopeeid://') ||
        url.startsWith('dana://') ||
        url.startsWith('linkaja://') ||
        url.startsWith('bca://') ||
        url.startsWith('mandiri://') ||
        url.startsWith('bni://') ||
        url.startsWith('bri://');
  }

  // ⛔ Tidak pernah buka browser. Hanya coba buka APP.
  Future<void> _launchDeepLinkToAppOnly(String url) async {
    if (_isLaunchingDeepLink) return;
    _isLaunchingDeepLink = true;

    try {
      Uri? uri;

      if (url.startsWith('gojek://') || url.startsWith('gopay://')) {
        uri = Uri.parse(url);
      } else if (url.startsWith('intent://')) {
        // Rekonstruksi ke <scheme>://<host+path> dari intent
        final reconstructed = _intentToCustomScheme(url);
        if (reconstructed != null) {
          uri = Uri.tryParse(reconstructed);
        }
      }

      if (uri != null && await canLaunchUrl(uri)) {
        // Launch ke APP (bukan browser)
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Jangan buka fallback https agar tidak lari ke browser
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aplikasi e-wallet tidak tersedia / tidak dapat dibuka.'),
            ),
          );
        }
      }
    } finally {
      _isLaunchingDeepLink = false;
    }
  }

  // Convert intent://...#Intent;scheme=gojek;...;end → gojek://host/path
  String? _intentToCustomScheme(String intentUrl) {
    try {
      // ambil bagian sebelum "#Intent"
      final before = intentUrl.split('#Intent').first; // intent://host/path
      final schemeMatch = RegExp(r'scheme=([^;]+);').firstMatch(intentUrl);
      if (!before.startsWith('intent://') || schemeMatch == null) return null;

      final scheme = schemeMatch.group(1)!; // ex: gojek / gopay
      final tail = before.substring('intent://'.length); // host/path...
      return '$scheme://$tail';
    } catch (_) {
      return null;
    }
  }

  Future<void> _handlePaymentSuccess() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final cartRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart');

      final cartSnapshot = await cartRef.get();
      for (var doc in cartSnapshot.docs) {
        await doc.reference.delete();
      }

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text("Pembayaran Sukses"),
          content: const Text("Terima kasih! Pesanan Anda berhasil dilakukan."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/home',
                      (route) => false,
                );
              },
              child: const Text("Kembali ke Beranda"),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      debugPrint('❌ Error saat hapus cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memproses pesanan')),
      );
    }
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran'),
        automaticallyImplyLeading: false,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
