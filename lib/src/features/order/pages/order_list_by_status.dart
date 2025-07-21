import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'order_detail_page.dart';

class OrderListByStatus extends StatelessWidget {
  final String status;

  const OrderListByStatus({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: currentUser?.uid)
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data?.docs ?? [];

        if (orders.isEmpty) {
          return const Center(child: Text('Belum ada pesanan dengan status ini'));
        }

        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final orderData = orders[index].data() as Map<String, dynamic>;
            final createdAt = orderData['createdAt'];
            final timestamp = createdAt is Timestamp ? createdAt.toDate() : null;
            final formattedDate = timestamp != null
                ? DateFormat('dd MMM yyyy – HH:mm').format(timestamp)
                : 'Tanggal tidak tersedia';

            final items = orderData['items'] as List<dynamic>? ?? [];

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text('Pesanan $formattedDate'),
                subtitle: Text('Jumlah item: ${items.length}\nStatus: $status'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderDetailPage(orderData: orderData),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
