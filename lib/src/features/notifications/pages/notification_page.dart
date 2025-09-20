import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  // Fungsi: Tandai notifikasi sudah dibaca
  Future<void> _markAsRead(String docId, List<dynamic> readBy) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || readBy.contains(userId)) return;

    await FirebaseFirestore.instance.collection('notifications').doc(docId).update({
      'readBy': FieldValue.arrayUnion([userId]),
    });
  }

  // Fungsi: Aksi jika notifikasi diklik
  void _handleNotificationTap(BuildContext context, Map<String, dynamic> data) async {
    final title = (data['title'] ?? '').toString().toLowerCase();
    final orderId = data['orderId'];

    if (title.contains('pesanan dikirim') && orderId != null) {
      try {
        final orderSnap = await FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .get();

        if (orderSnap.exists) {
          final orderData = orderSnap.data();
          orderData?['orderId'] = orderId; // Tambahkan orderId manual
          Navigator.pushNamed(
            context,
            '/order-detail',
            arguments: orderData,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data pesanan tidak ditemukan')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka detail pesanan: $e')),
        );
      }
    }

    // Tambahan jika ingin navigasi lain
    // else if (title.contains('promo')) Navigator.pushNamed(context, '/promo');
  }

  // Fungsi: Menentukan ikon notifikasi
  IconData _getNotificationIcon(String? title) {
    final lowerTitle = title?.toLowerCase() ?? '';
    if (lowerTitle.contains('dikirim')) return Icons.local_shipping_rounded;
    if (lowerTitle.contains('promo') || lowerTitle.contains('diskon')) return Icons.percent;
    return Icons.notifications_active_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Terjadi kesalahan'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('Belum ada notifikasi'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
              final formattedDate = createdAt != null
                  ? DateFormat('dd MMM yyyy, HH:mm').format(createdAt)
                  : '-';

              final readBy = List<String>.from(data['readBy'] ?? []);
              final isUnread = !readBy.contains(userId);

              // Tandai sebagai sudah dibaca
              _markAsRead(doc.id, readBy);

              return Dismissible(
                key: Key(doc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) {
                  FirebaseFirestore.instance.collection('notifications').doc(doc.id).delete();
                },
                child: GestureDetector(
                  onTap: () => _handleNotificationTap(context, data),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUnread ? Colors.orange[50] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _getNotificationIcon(data['title']),
                          color: Colors.orange,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['title'] ?? 'Tanpa Judul',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(data['message'] ?? ''),
                              const SizedBox(height: 8),
                              Text(
                                formattedDate,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
