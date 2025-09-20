import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../blocs/cart/cart_bloc.dart';
import '../../../blocs/cart/cart_event.dart';
import '../../address/pages/edit_address_page.dart';
import '../../shipping/utils/shipping_helper.dart';
import '../helpers/midtrans_helper.dart';
import 'payment_webview_page.dart';

class CheckoutPage extends StatefulWidget {
  final List<Map<String, dynamic>> selectedItems;

  const CheckoutPage({super.key, required this.selectedItems});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  Map<String, dynamic>? address;
  double shippingCost = 0;
  int subtotal = 0;
  bool isLoading = true;
  final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp');

  // ====== CACHE untuk WPM biar hemat query ======
  final Map<String, double> _wpmCache = {};

  // ====== fallback mapping (kalau semua cara gagal) ======
  static const Map<String, double> _guessWpm = {
    'nya': 0.15,
    'nyaf': 0.10,
    'nylhy': 0.08,
    'nym': 0.12,        // ± mendekati yang kamu isi (0.1216)
    'nymhy': 0.09,
    'nyy': 0.30,
    'nyyhy': 0.22,
    'cctv': 0.04,
    'coaxial': 0.05,
    'kabel power': 0.12,
  };

  // Ambil weightPerMeter dari item; kalau kosong → products; kalau masih kosong → name/jenis → fallback
  Future<double> _resolveWeightPerMeter(Map<String, dynamic> item) async {
    // 1) dari item langsung
    final any = item['weightPerMeter'];
    final wpmFromItem =
    (any is num) ? any.toDouble() : double.tryParse('$any');
    if (wpmFromItem != null && wpmFromItem > 0) return wpmFromItem;

    // 2) dari dokumen produk berdasarkan id
    String productId =
    (item['productId'] ?? item['id'] ?? item['docId'] ?? item['product_id'] ?? '').toString();
    if (productId.isNotEmpty) {
      if (_wpmCache.containsKey(productId)) return _wpmCache[productId]!;
      try {
        final doc = await FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final anyDoc = data['weightPerMeter'];
          final wpm =
          (anyDoc is num) ? anyDoc.toDouble() : double.tryParse('$anyDoc') ?? 0.0;
          if (wpm > 0) {
            _wpmCache[productId] = wpm;
            return wpm;
          }
        }
      } catch (_) {}
    }

    // 3) cari produk by nama (kalau id gak ada/beda)
    final name = (item['name'] ?? '').toString();
    if (name.isNotEmpty) {
      final q = await FirebaseFirestore.instance
          .collection('products')
          .where('name', isEqualTo: name)
          .limit(1)
          .get();
      if (q.docs.isNotEmpty) {
        final d = q.docs.first.data();
        final anyDoc = d['weightPerMeter'];
        final wpm =
        (anyDoc is num) ? anyDoc.toDouble() : double.tryParse('$anyDoc') ?? 0.0;
        if (wpm > 0) return wpm;
      }
    }

    // 4) fallback: tebak dari jenis/nama
    final jenis = (item['jenisKabel'] ?? name).toString().toLowerCase();
    for (final key in _guessWpm.keys) {
      if (jenis.contains(key)) return _guessWpm[key]!;
    }
    // paling mentok: 0 (biar aman)
    return 0.0;
  }

  @override
  void initState() {
    super.initState();
    _initCheckout();
  }

  Future<void> _initCheckout() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User belum login');

      // Ambil alamat utama di users/{uid}/addresses
      final primaryQ = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('addresses')
          .where('isPrimary', isEqualTo: true)
          .limit(1)
          .get();

      if (primaryQ.docs.isNotEmpty) {
        address = primaryQ.docs.first.data();
      } else {
        final anyQ = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('addresses')
            .limit(1)
            .get();
        address = anyQ.docs.isNotEmpty ? anyQ.docs.first.data() : null;
      }

      // Hitung subtotal
      subtotal = widget.selectedItems.fold<int>(0, (prev, item) {
        final qty = (item['quantity'] ?? 1) as int;
        final price = (item['totalPrice'] ?? 0) as int;
        return prev + (qty * price);
      });

      // Hitung ongkir berdasarkan area & berat
      shippingCost = 0;
      if (address != null) {
        final areaRaw = (address!['provinsiKota'] ?? '').toString();
        final area = areaRaw.toLowerCase().replaceAll(',', '').trim();

        double totalWeight = 0.0;
        for (final item in widget.selectedItems) {
          final qtyAny = item['quantity'] ?? 1;
          final lengthAny = item['panjang'] ?? item['length'] ?? 0;

          final qty =
          (qtyAny is num) ? qtyAny.toDouble() : double.tryParse('$qtyAny') ?? 0.0;
          final length = (lengthAny is num)
              ? lengthAny.toDouble()
              : double.tryParse('$lengthAny') ?? 0.0;
          final wpm = await _resolveWeightPerMeter(item);

          totalWeight += qty * length * wpm;
        }

        if (area.isNotEmpty && totalWeight > 0) {
          shippingCost = await ShippingHelper.calculateShipping(
            area: area,
            totalWeight: totalWeight,
          );
        } else {
          // Debug bantuan saat dev
          // ignore: avoid_print
          print('[Checkout] area="$area", totalWeight=$totalWeight (cek wpm/length)');
        }
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data checkout: ${e.message ?? e.code}')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Terjadi kesalahan saat memuat checkout.')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _handlePayment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final total = subtotal + shippingCost.toInt();

    try {
      final result = await createMidtransTransaction(
        userId: user.uid,
        userName: user.displayName ?? user.email ?? 'User',
        userAddress: address?['alamat'] ?? '',
        items: widget.selectedItems,
        grossAmount: total,
        shippingCost: shippingCost.toInt(),
      );

      final snapUrl = result['snapUrl'];
      final orderId = result['orderId'];

      final res = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentWebViewPage(
            url: snapUrl,
            orderId: orderId,
            totalAmount: total,
          ),
        ),
      );

      if (res == true && mounted) {
        context.read<CartBloc>().add(ClearCart());
        Navigator.pushNamedAndRemoveUntil(context, '/order-history', (route) => false);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memproses pembayaran.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.transparent,
        foregroundColor: cs.onSurface,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Alamat Pengiriman',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const EditAddressPage()),
                        );
                        await _initCheckout();
                      },
                      child: const Text('Edit'),
                    ),
                  ],
                ),
                // Kartu alamat
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black.withOpacity(0.5) : Colors.black12,
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: (address != null)
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(address?['alamat'] ?? '-', style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 4),
                      Text('Telp: ${address?['telepon'] ?? '-'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withOpacity(0.7),
                          )),
                    ],
                  )
                      : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Belum ada alamat utama', style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const EditAddressPage()),
                          );
                          await _initCheckout();
                        },
                        child: const Text('Tambah Alamat'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Text('Produk Dipesan',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                ...widget.selectedItems.map(
                      (item) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black.withOpacity(0.5) : Colors.black12,
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            (item['imageUrl'] ?? '').toString(),
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.image),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['name']?.toString() ?? '',
                                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                              Text(
                                '${item['quantity'] ?? 1}x - Panjang: ${(item['panjang'] ?? item['length'] ?? '-')}m',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formatter.format(item['totalPrice'] ?? 0),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Text('Ringkasan',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildSummaryRow(context, 'Subtotal', subtotal),
                _buildSummaryRow(context, 'Ongkos Kirim', shippingCost.toInt()),
                Divider(color: theme.dividerColor),
                _buildSummaryRow(context, 'Total Bayar', subtotal + shippingCost.toInt(), bold: true),
              ],
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.scaffoldBackgroundColor,
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (address == null) ? null : _handlePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Bayar Sekarang'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, int value, {bool bold = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            formatter.format(value),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
