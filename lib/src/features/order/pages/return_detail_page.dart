import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReturnDetailPage extends StatelessWidget {
  final String orderId;

  const ReturnDetailPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Retur'),
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('orders').doc(orderId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Data tidak ditemukan'));
          }

          final orderData = snapshot.data!.data() as Map<String, dynamic>;
          final returnData = orderData['returnDetails'] as Map<String, dynamic>?;
          final returnStatus = orderData['returnStatus'] ?? 'Diproses';

          if (returnData == null) {
            return const Center(child: Text('Data retur belum tersedia'));
          }

          final reason = returnData['reason'] ?? '-';
          final notes = returnData['notes'] ?? '-';
          final createdAt = returnData['createdAt'];
          final date = createdAt is Timestamp ? createdAt.toDate() : null;
          final formattedDate = date != null
              ? DateFormat('dd MMM yyyy – HH:mm').format(date)
              : 'Tanggal tidak tersedia';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Status Retur', style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Chip(
                label: Text(returnStatus),
                backgroundColor: returnStatus == 'Diterima'
                    ? Colors.green.shade100
                    : returnStatus == 'Ditolak'
                    ? Colors.red.shade100
                    : Colors.orange.shade100,
              ),
              const SizedBox(height: 24),

              Text('Alasan Retur', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Text(reason, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),

              Text('Catatan Tambahan', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Text(notes, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),

              Text('Diajukan pada', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Text(formattedDate, style: theme.textTheme.bodyMedium),
            ],
          );
        },
      ),
    );
  }
}
