import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'order_detail_page.dart';
import 'return_form_page.dart';

class OrderListByStatus extends StatelessWidget {
  final String status;

  const OrderListByStatus({super.key, required this.status});

  Future<void> _confirmOrderReceived(BuildContext context, String orderId) async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.dialogBackgroundColor,
        title: const Text('Konfirmasi'),
        content: const Text('Apakah kamu sudah menerima pesanan ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ya, Sudah Terima')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('orders').doc(orderId).update({'status': 'Selesai'});
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pesanan ditandai sebagai Selesai')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal memperbarui status')));
        }
      }
    }
  }

  Future<void> _requestOrderCancellation(BuildContext context, String orderId) async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.dialogBackgroundColor,
        title: const Text('Ajukan Pembatalan'),
        content: const Text('Yakin ingin membatalkan pesanan ini?\nAdmin akan memverifikasi permintaan kamu.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ajukan')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('orders').doc(orderId).update({'dispute': true});
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permintaan pembatalan dikirim')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mengajukan pembatalan')));
        }
      }
    }
  }

  Future<void> _requestReturn(BuildContext context, String orderId) async {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ReturnFormPage(orderId: orderId)));
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: currentUser?.uid)
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Terjadi kesalahan: ${snapshot.error}', style: theme.textTheme.bodyMedium));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data?.docs ?? [];

        if (orders.isEmpty) {
          return Center(child: Text('Belum ada pesanan dengan status ini', style: theme.textTheme.bodyMedium));
        }

        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final doc = orders[index];
            final orderData = doc.data() as Map<String, dynamic>;
            final createdAt = orderData['createdAt'];
            final timestamp = createdAt is Timestamp ? createdAt.toDate() : null;
            final formattedDate = timestamp != null
                ? DateFormat('dd MMM yyyy – HH:mm').format(timestamp)
                : 'Tanggal tidak tersedia';

            final items = orderData['items'] as List<dynamic>? ?? [];
            final hasRequestedCancel = orderData['dispute'] == true;
            final hasRequestedReturn = orderData['returnRequested'] == true;
            final returnStatus = orderData['returnStatus'] as String?;

            return Card(
              color: theme.cardColor,
              surfaceTintColor: Colors.transparent,
              elevation: 2,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.dividerColor),
              ),
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      'Pesanan $formattedDate',
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Jumlah item: ${items.length}\nStatus: $status',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
                      ),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16, color: cs.onSurface),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderDetailPage(orderData: orderData),
                        ),
                      );
                    },
                  ),

                  if (status == 'Dikirim') ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmOrderReceived(context, doc.id),
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Pesanan Diterima'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    if (!hasRequestedCancel)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: ElevatedButton.icon(
                          onPressed: () => _requestOrderCancellation(context, doc.id),
                          icon: const Icon(Icons.cancel),
                          label: const Text('Ajukan Pembatalan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(44),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          'Permintaan pembatalan sedang diproses admin.',
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.redAccent),
                        ),
                      ),
                  ],

                  if (status == 'Selesai') ...[
                    if (!hasRequestedReturn && returnStatus == null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: ElevatedButton.icon(
                          onPressed: () => _requestReturn(context, doc.id),
                          icon: const Icon(Icons.assignment_return),
                          label: const Text('Ajukan Retur'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(44),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      )
                    else if (hasRequestedReturn && returnStatus == null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          'Permintaan retur sedang diproses admin.',
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.orange),
                        ),
                      )
                    else if (returnStatus == 'Disetujui')
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Text(
                            'Retur telah disetujui. Kurir akan segera mengambil pesanan kamu.',
                            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.green),
                          ),
                        )
                      else if (returnStatus == 'Ditolak')
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Text(
                              '❌ Permintaan retur ditolak oleh admin.',
                              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red),
                            ),
                          ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
