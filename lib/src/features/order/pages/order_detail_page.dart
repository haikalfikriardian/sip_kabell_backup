import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderDetailPage extends StatelessWidget {
  final Map<String, dynamic> orderData;

  const OrderDetailPage({super.key, required this.orderData});

  @override
  Widget build(BuildContext context) {
    final createdAt = orderData['createdAt'];
    final timestamp = createdAt != null ? (createdAt as Timestamp).toDate() : null;
    final formattedDate = timestamp != null
        ? DateFormat('dd MMM yyyy – HH:mm').format(timestamp)
        : 'Tanggal tidak tersedia';

    final address = orderData['userAddress'] ?? 'Alamat tidak tersedia';
    final status = orderData['status'] ?? 'Status tidak tersedia';
    final items = orderData['items'] as List<dynamic>? ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text("Detail Pesanan")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Tanggal: $formattedDate"),
            const SizedBox(height: 8),
            Text("Alamat: $address"),
            const SizedBox(height: 8),
            Text("Status: $status"),
            const SizedBox(height: 16),

            const Text("Daftar Produk:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: item['imageUrl'] != null
                        ? Image.network(item['imageUrl'], width: 50, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image))
                        : const Icon(Icons.image_not_supported),
                    title: Text(item['name'] ?? 'Produk'),
                    subtitle: Text("Warna: ${item['color']} | Panjang: ${item['length']} m"),
                    trailing: Text('Rp ${item['price'] ?? 0}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
