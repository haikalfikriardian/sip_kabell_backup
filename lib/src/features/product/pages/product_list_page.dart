import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import 'product_detail_page.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  String selectedCategory = 'All';
  String searchQuery = '';

  final List<String> categories = [
    'All',
    'Tegangan Rendah',
    'Audio Video',
    'CCTV',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:
        theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: cs.onSurface),
        title: Text('All Products', style: TextStyle(color: cs.onSurface)),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari produk...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.cardColor,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
              ),
              onChanged: (v) => setState(() => searchQuery = v.toLowerCase()),
            ),
          ),
          const SizedBox(height: 12),

          // Category chips
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, i) {
                final cat = categories[i];
                final sel = selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: sel,
                    selectedColor: cs.primary,
                    backgroundColor: theme.cardColor,
                    labelStyle: TextStyle(
                      color: sel ? cs.onPrimary : cs.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) => setState(() => selectedCategory = cat),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Grid
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Terjadi kesalahan',
                        style: TextStyle(color: cs.onSurface)),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                final list = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final name =
                  (data['name'] ?? '').toString().toLowerCase().trim();
                  final cat = (data['category'] ?? '').toString();
                  final matchCat =
                      selectedCategory == 'All' || cat == selectedCategory;
                  final matchSearch = name.contains(searchQuery);
                  return matchCat && matchSearch;
                }).toList();

                if (list.isEmpty) {
                  return Center(
                    child: Text('Produk tidak ditemukan.',
                        style: TextStyle(color: cs.onSurface)),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    itemCount: list.length,
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      // disamain dengan Home agar layout konsisten & anti-overflow
                      childAspectRatio: 0.68,
                    ),
                    itemBuilder: (context, i) {
                      final data =
                      list[i].data() as Map<String, dynamic>;

                      final name = (data['name'] ?? 'Nama Produk').toString();
                      final img = (data['imageUrl'] ?? '').toString();
                      final pricePerMeter =
                      (data['pricePerMeter'] ?? '0').toString();

                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProductDetailPage(productData: data),
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.black.withOpacity(0.5)
                                    : Colors.black12,
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Thumbnail square (nempel ke kotak)
                              AspectRatio(
                                aspectRatio: 1,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: img.isNotEmpty
                                      ? Image.network(
                                    img,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                    const Center(
                                      child: Icon(Icons.broken_image,
                                          size: 48),
                                    ),
                                  )
                                      : Container(
                                    color: theme.dividerColor
                                        .withOpacity(.12),
                                    child: Icon(Icons.broken_image,
                                        color: cs.onSurface
                                            .withOpacity(.6)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Title (max 2 lines)
                              Flexible(
                                child: Text(
                                  name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),

                              // Price per meter (sama persis format Home)
                              Text(
                                'Rp $pricePerMeter/m',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurface.withOpacity(0.7),
                                ),
                              ),

                              const Spacer(),

                              // FAB cart bulat (Iconsax.shopping_bag) — sama dengan Home
                              Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: cs.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Iconsax.shopping_bag,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
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
          ),
        ],
      ),
    );
  }
}
