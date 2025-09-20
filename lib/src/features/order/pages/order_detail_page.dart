import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';

class OrderDetailPage extends StatelessWidget {
  final Map<String, dynamic> orderData;

  const OrderDetailPage({super.key, required this.orderData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    DateTime? ts;
    final rawCreatedAt = orderData['createdAt'];
    if (rawCreatedAt is Timestamp) {
      ts = rawCreatedAt.toDate();
    } else if (rawCreatedAt is DateTime) {
      ts = rawCreatedAt;
    } else if (rawCreatedAt is String) {
      ts = DateTime.tryParse(rawCreatedAt);
    }
    final formattedDate =
    ts != null ? DateFormat('dd MMM yyyy – HH:mm').format(ts) : 'Tanggal tidak tersedia';

    final orderId = (orderData['orderId'] ?? 'ID tidak tersedia').toString();
    final address = (orderData['userAddress'] ?? 'Alamat tidak tersedia').toString();
    final status = (orderData['status'] ?? 'Status tidak tersedia').toString();

    final List itemsDynamic = (orderData['items'] as List?) ?? const [];
    final List<Map<String, dynamic>> items = itemsDynamic
        .whereType<Map>()
        .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
        .toList();

    final currentIndex = _statusIndex(status);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Detail Pesanan"),
        backgroundColor: theme.appBarTheme.backgroundColor ?? Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _InfoCard(
              children: [
                _InfoRow(label: "Order ID", value: orderId),
                const SizedBox(height: 8),
                _InfoRow(label: "Tanggal", value: formattedDate),
                const SizedBox(height: 8),
                _InfoRow(label: "Alamat", value: address),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      "Status",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _StatusBadge(text: status),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoCard(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: [
                const Text("Order Status",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _StatusStepper(current: currentIndex),
              ],
            ),
            const SizedBox(height: 16),
            Text("Daftar Produk:",
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...items.map((it) => _ProductTile(item: it)),
          ],
        ),
      ),
    );
  }

  static int _statusIndex(String status) {
    final s = status.toLowerCase().trim();
    if (s.contains('tunggu') || s.contains('menunggu') || s.contains('unpaid') || s.contains('payment')) {
      return 0;
    }
    if (s.contains('proses') || s.contains('process') || s.contains('diproses') || s.contains('processing')) {
      return 1;
    }
    if (s.contains('kirim') || s.contains('dikirim') || s.contains('shipped') || s.contains('shipping')) {
      return 2;
    }
    if (s.contains('selesai') || s.contains('complete') || s.contains('delivered')) {
      return 3;
    }
    return 0;
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final nf = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    final name = (item['name'] ?? 'Produk').toString();
    final color = (item['color'] ?? '-').toString();
    final length = (item['length'] ?? item['panjang'])?.toString() ?? '-';

    final img = (item['imageUrl'] ?? item['image'])?.toString() ?? '';
    final priceN = (item['totalPrice'] is num) ? (item['totalPrice'] as num) : 0;
    final price = nf.format(priceN);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
          SizedBox(
            width: 56,
            child: AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: img.isNotEmpty
                    ? Image.network(
                  img,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      ColoredBox(color: theme.dividerColor.withOpacity(0.1)),
                )
                    : Container(
                  color: theme.dividerColor.withOpacity(0.1),
                  child: const Icon(Icons.image_not_supported),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  "Warna: $color  |  Panjang: $length m",
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(price, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children, this.padding});
  final List<Widget> children;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.5) : Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.text});
  final String text;

  Color _bg(String t, BuildContext context) {
    final theme = Theme.of(context);
    final s = t.toLowerCase();
    if (s.contains('batal') || s.contains('cancel')) {
      return Colors.red.withOpacity(0.15);
    }
    return theme.colorScheme.primary.withOpacity(0.15);
  }

  Color _fg(String t, BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = t.toLowerCase();
    if (s.contains('batal') || s.contains('cancel')) return Colors.red;
    return cs.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _bg(text, context),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: _fg(text, context), fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

class _StatusStepper extends StatelessWidget {
  const _StatusStepper({required this.current});
  final int current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    const labels = [
      'Menunggu\nPembayaran',
      'Diproses',
      'Dikirim',
      'Selesai',
    ];

    const icons = [
      Iconsax.timer,
      Iconsax.box,
      Iconsax.truck_fast,
      Iconsax.home,
    ];

    final Color activeColor = cs.primary;
    final Color inactiveColor = cs.onSurface.withOpacity(0.35);

    const double dotSize = 12;
    const double lineThickness = 3;

    Color _c(bool active) => active ? activeColor : inactiveColor;

    return Column(
      children: [
        Row(
          children: List.generate(4, (i) {
            final isActive = i <= current;
            return Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icons[i], size: 28, color: _c(isActive)),
                  const SizedBox(height: 6),
                  Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isActive ? cs.onSurface : cs.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            );
          }),
        ),
        SizedBox(
          height: dotSize,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final centers = List<double>.generate(4, (i) => w * ((2 * i + 1) / 8));
              final segW = w / 4;
              final lineTop = (dotSize - lineThickness) / 2;

              return Stack(
                children: [
                  for (int i = 0; i < 3; i++)
                    Positioned(
                      left: centers[i],
                      top: lineTop,
                      width: segW,
                      child: Container(height: lineThickness, color: inactiveColor),
                    ),
                  for (int i = 0; i < current; i++)
                    Positioned(
                      left: centers[i],
                      top: lineTop,
                      width: segW,
                      child: Container(height: lineThickness, color: activeColor),
                    ),
                  for (int i = 0; i < 4; i++)
                    Positioned(
                      left: centers[i] - (dotSize / 2),
                      top: 0,
                      child: Container(
                        width: dotSize,
                        height: dotSize,
                        decoration: BoxDecoration(
                          color: _c(i <= current),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
