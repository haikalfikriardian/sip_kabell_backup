// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:webview_flutter/webview_flutter.dart';
// import 'package:url_launcher/url_launcher.dart';
//
// class PaymentWebViewPage extends StatefulWidget {
//   final String url;
//   final String orderId;
//   final int totalAmount;
//
//   const PaymentWebViewPage({
//     super.key,
//     required this.url,
//     required this.orderId,
//     required this.totalAmount,
//   });
//
//   @override
//   State<PaymentWebViewPage> createState() => _PaymentWebViewPageState();
// }
//
// class _PaymentWebViewPageState extends State<PaymentWebViewPage> {
//   late final WebViewController _controller;
//   bool _transactionCompleted = false;
//
//   @override
//   void initState() {
//     super.initState();
//
//     _controller = WebViewController()
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..setNavigationDelegate(
//         NavigationDelegate(
//           // Log URL saat mulai & selesai load (ngebantu debug Snap)
//           onPageStarted: (url) {
//             if (kDebugMode) debugPrint('[SNAP][start] $url');
//           },
//           onPageFinished: (String url) async {
//             if (kDebugMode) debugPrint('[SNAP][done ] $url');
//             if (_transactionCompleted) return;
//
//             // Deteksi sukses dari konten halaman (backup kalau tidak ada redirect)
//             try {
//               final html = await _controller.runJavaScriptReturningResult(
//                 "document.documentElement.outerHTML",
//               );
//               final htmlString = html.toString().toLowerCase();
//
//               // Beberapa kemungkinan phrase dari halaman Snap/payment gateway
//               final success = htmlString.contains('transaction is successful') ||
//                   htmlString.contains('payment successful') ||
//                   htmlString.contains('status: paid') ||
//                   htmlString.contains('pembayaran berhasil');
//
//               if (success) {
//                 _transactionCompleted = true;
//                 await _handlePaymentSuccess();
//                 return;
//               }
//
//               final failed = htmlString.contains('transaction failed') ||
//                   htmlString.contains('pembayaran gagal');
//               if (failed && mounted) {
//                 _showFailureSnack();
//               }
//             } catch (_) {
//               // no-op
//             }
//           },
//
//           // **Penting**: Intercept & buka deeplink e-wallet di luar WebView
//           onNavigationRequest: (NavigationRequest request) async {
//             final url = request.url;
//             if (kDebugMode) debugPrint('[SNAP][nav ] $url');
//
//             // Skema yang harus dibuka di external app (GoPay/OVO/ShopeePay, dll)
//             if (_isDeepLink(url)) {
//               await _launchDeepLink(url);
//               return NavigationDecision.prevent;
//             }
//
//             return NavigationDecision.navigate;
//           },
//
//           onWebResourceError: (error) {
//             if (kDebugMode) {
//               debugPrint(
//                   '[SNAP][error] ${error.errorCode} - ${error.description}');
//             }
//           },
//         ),
//       )
//       ..loadRequest(Uri.parse(widget.url));
//   }
//
//   bool _isDeepLink(String url) {
//     // Intent / deeplink umum untuk e-wallet
//     return url.startsWith('intent://') ||
//         url.startsWith('gojek://') ||
//         url.startsWith('gopay://') ||
//         url.startsWith('ovo://') ||
//         url.startsWith('shopeeid://') ||
//         url.startsWith('dana://') ||
//         url.startsWith('linkaja://') ||
//         url.startsWith('bca://') ||
//         url.startsWith('mandiri://') ||
//         url.startsWith('bni://') ||
//         url.startsWith('bri://');
//   }
//
//   Future<void> _launchDeepLink(String url) async {
//     Uri? uri = Uri.tryParse(url);
//
//     // Khusus intent:// dari Android – coba extract fallback URL
//     if (url.startsWith('intent://')) {
//       // Banyak intent:// Snap menyimpan fallback di "S.browser_fallback_url"
//       final fallback = _extractIntentFallback(url);
//       if (fallback != null) {
//         uri = Uri.tryParse(fallback);
//       }
//     }
//
//     if (uri != null && await canLaunchUrl(uri)) {
//       await launchUrl(uri, mode: LaunchMode.externalApplication);
//     } else {
//       // Kalau aplikasi belum terpasang atau gagal launch, kasih info
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Tidak dapat membuka aplikasi pembayaran. '
//               'Coba instal/aktifkan aplikasinya terlebih dahulu.'),
//         ),
//       );
//     }
//   }
//
//   String? _extractIntentFallback(String intentUrl) {
//     // Format intent biasanya: intent://...#Intent;...;S.browser_fallback_url=https%3A%2F%2F...;end;
//     final match = RegExp(r'S\.browser_fallback_url=([^;]+);')
//         .firstMatch(intentUrl);
//     if (match != null) {
//       final encoded = match.group(1);
//       if (encoded != null) {
//         return Uri.decodeComponent(encoded);
//       }
//     }
//     return null;
//   }
//
//   Future<void> _handlePaymentSuccess() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;
//
//     try {
//       // Hapus cart user setelah pembayaran sukses
//       final cartRef = FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .collection('cart');
//
//       final cartSnapshot = await cartRef.get();
//       for (var doc in cartSnapshot.docs) {
//         await doc.reference.delete();
//       }
//
//       if (!mounted) return;
//
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (_) => AlertDialog(
//           title: const Text("Pembayaran Sukses"),
//           content: const Text("Terima kasih! Pesanan Anda berhasil dilakukan."),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pushNamedAndRemoveUntil(
//                   '/home',
//                       (route) => false,
//                 );
//               },
//               child: const Text("Kembali ke Beranda"),
//             ),
//           ],
//         ),
//       );
//     } catch (e) {
//       if (!mounted) return;
//
//       debugPrint('❌ Error saat hapus cart: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Gagal memproses pesanan')),
//       );
//     }
//   }
//
//   void _showFailureSnack() {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Transaksi gagal diproses.')),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Pembayaran'),
//         automaticallyImplyLeading: false,
//       ),
//       body: WebViewWidget(controller: _controller),
//     );
//   }
// }
