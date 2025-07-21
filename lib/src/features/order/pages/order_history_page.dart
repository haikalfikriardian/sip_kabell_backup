import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'order_list_by_status.dart';

class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Kamu belum login')),
      );
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Riwayat Pesanan"),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: "Menunggu Pembayaran"),
              Tab(text: "Diproses"),
              Tab(text: "Selesai"),
              Tab(text: "Dibatalkan"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            OrderListByStatus(status: "Menunggu Pembayaran"),
            OrderListByStatus(status: "Diproses"),
            OrderListByStatus(status: "Selesai"),
            OrderListByStatus(status: "Dibatalkan"),
          ],
        ),
      ),
    );
  }
}
