// lib/src/features/auth/pages/home_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';

import '../../product/pages/product_detail_page.dart';
import '../product/pages/search_product_page.dart';
import '../../../../widgets/side_menu.dart';
import '../../../blocs/cart/cart_bloc.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String selectedCategory = 'All';
  int selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() => selectedIndex = index);
    switch (index) {
      case 0:
        _navigateTo(const HomePage());
        break;
      case 1:
        Navigator.pushNamed(context, '/wishlist');
        break;
      case 2:
        Navigator.pushNamed(context, '/notifications');
        break;
      case 3:
        Navigator.pushNamed(context, '/my-profile');
        break;
    }
  }

  void _navigateTo(Widget page) {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: SideMenu(
        onProfileTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/my-profile');
        },
      ),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor ?? Colors.transparent,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Iconsax.menu, color: cs.onSurface),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text("Home", style: TextStyle(color: cs.onSurface)),
        actions: [
          IconButton(
            icon: Icon(Iconsax.search_normal_1, color: cs.onSurface),
            onPressed: () => _navigateTo(const SearchProductPage()),
          ),
          IconButton(
            icon: Icon(Iconsax.clock, color: cs.onSurface),
            tooltip: 'Riwayat Pesanan',
            onPressed: () => Navigator.pushNamed(context, '/order-history'),
          ),
        ],
      ),
      body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
      // === BANNER ===
      StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('banners')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Gagal memuat banner', style: TextStyle(color: cs.onSurface)));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final bannerDocs = snapshot.data?.docs ?? [];
        if (bannerDocs.isEmpty) return Center(child: Text('Belum ada banner', style: TextStyle(color: cs.onSurface)));

        final bannerUrls = bannerDocs
            .map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final url = data['imageUrl'];
          return url is String ? url : null;
        })
            .whereType<String>()
            .toList();

        return CarouselSlider(
          options: CarouselOptions(
            height: 140,
            autoPlay: true,
            enlargeCenterPage: true,
            viewportFraction: 0.9,
            autoPlayInterval: const Duration(seconds: 3),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.fastOutSlowIn,
          ),
          items: bannerUrls.map((url) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) =>
                const Center(child: Icon(Icons.broken_image, size: 48)),
              ),
            );
          }).toList(),
        );
      },
    ),

    const SizedBox(height: 24),

    Text('Produk Paling Dicari',
    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
    const SizedBox(height: 12),

    StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('products')
        .orderBy('soldCount', descending: true)
        .limit(4)
        .snapshots(),
    builder: (context, snapshot) {
    if (snapshot.hasError) {
    return Text('Gagal memuat produk', style: TextStyle(color: cs.onSurface));
    }
    if (snapshot.connectionState == ConnectionState.waiting) {
    return const Center(child: CircularProgressIndicator());
    }

    final docs = snapshot.data?.docs ?? [];
    if (docs.isEmpty) return Text('Belum ada produk terjual', style: TextStyle(color: cs.onSurface));

    return SizedBox(
    height: 240,
    child: ListView.builder(
    scrollDirection: Axis.horizontal,
    itemCount: docs.length,
    itemBuilder: (context, index) {
    final product = docs[index].data() as Map<String, dynamic>;
    return GestureDetector(
    onTap: () => _navigateTo(ProductDetailPage(productData: product)),
    child: Container(
    width: 160,
    margin: const EdgeInsets.only(right: 12),
    decoration: BoxDecoration(
    color: theme.cardColor,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
    BoxShadow(
    color: cs.shadow.withOpacity(0.1),
    blurRadius: 6,
    offset: const Offset(0, 2),
    ),
    ],
    ),
    padding: const EdgeInsets.all(8),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    AspectRatio(
    aspectRatio: 1,
    child: ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: Image.network(
    product['imageUrl'] ?? '',
    fit: BoxFit.cover,
    errorBuilder: (context, error, stackTrace) =>
    const Center(child: Icon(Icons.broken_image, size: 48)),
    ),
    ),
    ),
    const SizedBox(height: 6),
    Text(
    product['name'] ?? 'Produk',
    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    ),
    const SizedBox(height: 4),
    Text(
    'Rp ${product['pricePerMeter'] ?? '0'}/m',
    style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.7)),
    ),
    ],
    ),
    ),
    );
    },
    ),
    );
    },
    ),

    const SizedBox(height: 24),
    // === KATEGORI & ALL PRODUK (lanjutan) ===
    Text('Categories',
    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
    const SizedBox(height: 12),
    SizedBox(
    height: 40,
    child: ListView(
    scrollDirection: Axis.horizontal,
    children: [
    _CategoryChip(
    label: 'All',
    selected: selectedCategory == 'All',
    onTap: () => setState(() => selectedCategory = 'All'),
    ),
    _CategoryChip(
    label: 'Tegangan Rendah',
    selected: selectedCategory == 'Tegangan Rendah',
    onTap: () => setState(() => selectedCategory = 'Tegangan Rendah'),
    ),
    _CategoryChip(
    label: 'Audio Video',
    selected: selectedCategory == 'Audio Video',
    onTap: () => setState(() => selectedCategory = 'Audio Video'),
    ),
    _CategoryChip(
    label: 'CCTV',
    selected: selectedCategory == 'CCTV',
    onTap: () => setState(() => selectedCategory = 'CCTV'),
    ),
    ],
    ),
    ),
    const SizedBox(height: 24),

    Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
    Text('All Product',
    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
    TextButton(
    onPressed: () => Navigator.pushNamed(context, '/product-list'),
    child: const Text("Lihat Semua"),
    ),
    ],
    ),
    const SizedBox(height: 12),

    // === PRODUK PER KATEGORI (LANJUTAN CODE YANG SUDAH ADA)
    // (JANGAN DIUBAH, LANJUTKAN DARI SINI SESUAI CODE SEBELUMNYA)
    // ...
    // 🟢 lanjutkan dari baris builder: (context, snapshot) { ... }
            StreamBuilder<QuerySnapshot>(
              stream: selectedCategory == 'All'
                  ? FirebaseFirestore.instance
                  .collection('products')
                  .orderBy('createdAt', descending: true)
                  .limit(10)
                  .snapshots()
                  : FirebaseFirestore.instance
                  .collection('products')
                  .where('category', isEqualTo: selectedCategory)
                  .orderBy('createdAt', descending: true)
                  .limit(10)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Gagal memuat produk', style: TextStyle(color: cs.onSurface));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Text('Belum ada produk');
                }

                return GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: docs.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.7,
                  ),
                  itemBuilder: (context, index) {
                    final product = docs[index].data() as Map<String, dynamic>;
                    return GestureDetector(
                      onTap: () => _navigateTo(ProductDetailPage(productData: product)),
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: cs.shadow.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AspectRatio(
                              aspectRatio: 1,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  product['imageUrl'] ?? '',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                  const Center(child: Icon(Icons.broken_image, size: 48)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              product['name'] ?? 'Produk',
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rp ${product['pricePerMeter'] ?? '0'}/m',
                              style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.7)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 80), // biar gak ketutup navbar
          ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/cart');
        },
        backgroundColor: Colors.orange,
        child: const Icon(Icons.shopping_cart, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(Iconsax.home, color: selectedIndex == 0 ? Colors.orange : Colors.grey),
                onPressed: () => _onItemTapped(0),
              ),
              IconButton(
                icon: Icon(Iconsax.heart, color: selectedIndex == 1 ? Colors.orange : Colors.grey),
                onPressed: () => _onItemTapped(1),
              ),
              const SizedBox(width: 40), // Space untuk FAB di tengah
              IconButton(
                icon: Icon(Iconsax.notification, color: selectedIndex == 2 ? Colors.orange : Colors.grey),
                onPressed: () => _onItemTapped(2),
              ),
              IconButton(
                icon: Icon(Iconsax.user, color: selectedIndex == 3 ? Colors.orange : Colors.grey),
                onPressed: () => _onItemTapped(3),
              ),
            ],
          ),
        ),
      ),

    );
  }
}

// === KATEGORI CHIP ===
class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: cs.primary,
        labelStyle: TextStyle(
          color: selected ? Colors.white : cs.onSurface,
        ),
        backgroundColor: cs.surfaceVariant,
      ),
    );
  }
}
