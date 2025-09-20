// lib/src/features/wishlist/pages/wishlist_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Wishlist')),
        body: Center(child: Text('Kamu belum login', style: TextStyle(color: cs.onSurface))),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist')),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('wishlist')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Terjadi kesalahan', style: TextStyle(color: cs.onSurface)));
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs;
          if (docs.isEmpty) return Center(child: Text('Wishlist kamu masih kosong 😅', style: TextStyle(color: cs.onSurface)));

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final w = docs[i].data() as Map<String, dynamic>;
              final productId = (w['productId'] ?? '').toString();

              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('products')
                    .doc(productId)
                    .snapshots(),
                builder: (context, pSnap) {
                  if (pSnap.connectionState == ConnectionState.waiting) {
                    return _card(theme, isDark, child: const ListTile(title: Text('Memuat...')));
                  }

                  if (!pSnap.hasData || !pSnap.data!.exists) {
                    return _card(
                      theme, isDark,
                      child: ListTile(
                        leading: const _SquareImage(url: null),
                        title: const Text('Produk tidak ditemukan'),
                        trailing: IconButton(
                          tooltip: 'Hapus',
                          icon: const Icon(Iconsax.trash, size: 22),
                          onPressed: () async => docs[i].reference.delete(),
                        ),
                      ),
                    );
                  }

                  final d = pSnap.data!.data() as Map<String, dynamic>;
                  final name = (d['name'] ?? d['productName'] ?? '').toString();

                  String? imageUrl;
                  if (d['image'] != null) imageUrl = d['image'].toString();
                  if (imageUrl == null && d['imageUrl'] != null) {
                    imageUrl = d['imageUrl'].toString();
                  }
                  if (imageUrl == null && d['images'] is List && (d['images'] as List).isNotEmpty) {
                    imageUrl = (d['images'] as List).first.toString();
                  }

                  final nf = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
                  String priceText = 'Rp 0';
                  if (d['price'] is num) {
                    priceText = nf.format(d['price']);
                  } else if (d['totalPrice'] is num) {
                    priceText = nf.format(d['totalPrice']);
                  } else if (d['pricePerMeter'] is num) {
                    priceText = '${nf.format(d['pricePerMeter'])} / m';
                  } else if (w['price'] is num) {
                    priceText = nf.format(w['price']);
                  }

                  return _card(
                    theme, isDark,
                    child: ListTile(
                      onTap: () {
                        Navigator.pushNamed(context, '/product-detail', arguments: d);
                      },
                      leading: _SquareImage(url: imageUrl),
                      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(priceText),
                      trailing: IconButton(
                        tooltip: 'Hapus',
                        icon: const Icon(Iconsax.trash, size: 22),
                        onPressed: () async => docs[i].reference.delete(),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _card(ThemeData theme, bool isDark, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.5) : Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SquareImage extends StatelessWidget {
  final String? url;
  const _SquareImage({this.url});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: url != null && url!.isNotEmpty
            ? Image.network(url!, fit: BoxFit.cover)
            : Container(
          color: Colors.grey.shade700.withOpacity(0.2),
          child: const Icon(Icons.image_not_supported),
        ),
      ),
    );
  }
}
