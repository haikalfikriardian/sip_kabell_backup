import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'order_list_by_status.dart';

class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Text('Kamu belum login', style: theme.textTheme.bodyMedium),
        ),
      );
    }

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.appBarTheme.backgroundColor ?? Colors.transparent,
          elevation: 0,
          title: Text(
            "Riwayat Pesanan",
            style: theme.textTheme.titleMedium?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: cs.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Theme( // pastiin TabBar ikut warna theme
                data: theme.copyWith(
                  tabBarTheme: theme.tabBarTheme.copyWith(
                    indicatorColor: cs.primary,
                    dividerColor: theme.dividerColor,
                    labelColor: cs.onSurface,
                    unselectedLabelColor: cs.onSurface.withOpacity(0.6),
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
                child: const TabBar(
                  isScrollable: true,
                  // indicatorColor & label colors sudah diatur via TabBarTheme di atas
                  indicatorWeight: 3,
                  tabs: [
                    Tab(text: "Menunggu Pembayaran"),
                    Tab(text: "Diproses"),
                    Tab(text: "Dikirim"),
                    Tab(text: "Selesai"),
                    Tab(text: "Dibatalkan"),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            OrderListByStatus(status: "Menunggu Pembayaran"),
            OrderListByStatus(status: "Diproses"),
            OrderListByStatus(status: "Dikirim"),
            OrderListByStatus(status: "Selesai"),
            OrderListByStatus(status: "Dibatalkan"),
          ],
        ),
      ),
    );
  }
}
