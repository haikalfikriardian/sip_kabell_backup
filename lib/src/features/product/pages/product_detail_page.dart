import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

// ✅ Wishlist
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../blocs/cart/cart_bloc.dart';
import '../../../blocs/cart/cart_event.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> productData;

  const ProductDetailPage({super.key, required this.productData});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  String? selectedColor;
  int? selectedPresetLength;
  int? customLength;
  final TextEditingController _customLengthController = TextEditingController();

  // ✅ state wishlist
  bool _wishloading = false;
  bool _isWishlisted = false;

  @override
  void initState() {
    super.initState();
    final data = widget.productData;
    final productId = (data['id'] ?? data['name'])?.toString();
    if (productId != null) _checkWishlist(productId);
  }

  Future<void> _checkWishlist(String productId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('wishlist')
        .doc(productId);
    final doc = await ref.get();
    if (mounted) setState(() => _isWishlisted = doc.exists);
  }

  Future<void> _toggleWishlist({
    required String productId,
    required Map<String, dynamic> productData,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login dulu')),
      );
      return;
    }

    if (mounted) setState(() => _wishloading = true);

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('wishlist')
        .doc(productId);

    final exists = (await ref.get()).exists;

    if (exists) {
      await ref.delete();
      if (mounted) {
        setState(() => _isWishlisted = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dihapus dari wishlist')),
        );
      }
    } else {
      await ref.set({
        'productId': productId,
        'createdAt': FieldValue.serverTimestamp(),
        'name': productData['name'],
        'image': productData['imageUrl'],
        'price': productData['pricePerMeter'] ?? productData['totalPrice'] ?? 0,
      }, SetOptions(merge: true));
      if (mounted) {
        setState(() => _isWishlisted = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ditambahkan ke wishlist')),
        );
      }
    }

    if (mounted) setState(() => _wishloading = false);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.productData;

    // ===== THEME HELPERS =====
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final onSurface = cs.onSurface;
    final muted = onSurface.withOpacity(0.6);
    final card = theme.cardColor;
    final scaffold = theme.scaffoldBackgroundColor;
    final divider = theme.dividerColor;

    // ===== ORIGINAL DATA =====
    List<String> availableColors = List<String>.from(data['availableColors'] ?? []);
    List<int> availableLengths = List<int>.from(data['availableLengths'] ?? []);
    int pricePerMeter = data['pricePerMeter'] ?? 0;
    int minLength = data['minLength'] ?? 100;
    bool allowCustom = data['allowCustomLength'] ?? false;

    int? selectedLength = customLength ?? selectedPresetLength;
    int totalPrice = selectedLength != null ? selectedLength * pricePerMeter : 0;

    final productId = data['id'] ?? data['name'];
    final cartItems = context.watch<CartBloc>().state.cartItems;

    final uniqueCartId = (selectedColor != null && selectedLength != null)
        ? '${productId}_${selectedColor}_$selectedLength'
        : '';

    final isInCart = cartItems.any((item) {
      final itemId = '${item['id']}_${item['color']}_${item['panjang']}';
      return itemId == uniqueCartId;
    });

    return Scaffold(
      backgroundColor: scaffold,
      appBar: AppBar(
        backgroundColor: scaffold,
        surfaceTintColor: Colors.transparent,
        foregroundColor: onSurface,
        elevation: 0,
        title: Text('Detail Produk',
            style: theme.textTheme.titleMedium?.copyWith(color: onSurface)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Gambar jadi KOTAK penuh dengan rasio 1:1
              AspectRatio(
                aspectRatio: 1, // square
                child: Container(
                  color: theme.brightness == Brightness.dark
                      ? cs.surfaceVariant.withOpacity(0.3)
                      : cs.surfaceVariant.withOpacity(0.6),
                  padding: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      data['imageUrl'] ?? '',
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Icon(Icons.broken_image, size: 60, color: muted),
                      ),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            data['name'] ?? 'Nama Kabel',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // ✅ Ikon love: pink saat aktif, idle mengikuti tema
                        IconButton(
                          tooltip: _isWishlisted ? 'Hapus dari wishlist' : 'Tambah ke wishlist',
                          onPressed: _wishloading
                              ? null
                              : () {
                            final id = (productId ?? '').toString();
                            if (id.isEmpty) return;
                            _toggleWishlist(
                              productId: id,
                              productData: Map<String, dynamic>.from(data),
                            );
                          },
                          icon: Icon(
                            _isWishlisted ? Icons.favorite : Icons.favorite_border,
                            color: _isWishlisted ? Colors.pink : onSurface,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data['description'] ?? 'Deskripsi belum tersedia.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                    ),
                    const SizedBox(height: 20),

                    Text('Pilih Warna',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: onSurface,
                        )),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      children: availableColors.map((color) {
                        final isSelected = selectedColor == color;
                        return GestureDetector(
                          onTap: () => setState(() => selectedColor = color),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: _getColorFromName(color),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? onSurface : divider,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: _needsInnerBorder(color)
                                ? Center(
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: onSurface, width: 1),
                                ),
                              ),
                            )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    Text('Pilih Panjang Preset (meter)',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: onSurface,
                        )),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      children: availableLengths.map((length) {
                        return ChoiceChip(
                          label: Text('$length m'),
                          selected: selectedPresetLength == length,
                          onSelected: (_) {
                            setState(() {
                              selectedPresetLength = length;
                              customLength = null;
                              _customLengthController.clear();
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    if (allowCustom) ...[
                      Text('Atau Masukkan Panjang Custom (meter)',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: onSurface,
                          )),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _customLengthController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Min $minLength meter',
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          final parsed = int.tryParse(value);
                          if (parsed != null && parsed >= minLength) {
                            setState(() {
                              customLength = parsed;
                              selectedPresetLength = null;
                            });
                          }
                        },
                      ),
                    ],

                    const SizedBox(height: 16),
                    Text(
                      'Total Harga: Rp ${NumberFormat('#,###', 'id_ID').format(totalPrice)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (selectedColor == null || selectedLength == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Pilih warna dan panjang dulu')),
                            );
                            return;
                          }

                          final productToAdd = {
                            'id': productId,
                            'name': data['name'],
                            'imageUrl': data['imageUrl'],
                            'color': selectedColor,
                            'panjang': selectedLength,
                            'quantity': 1,
                            'pricePerMeter': pricePerMeter,
                            'totalPrice': totalPrice,
                          };

                          final uniqueId = '${productId}_${selectedColor}_$selectedLength';

                          if (isInCart) {
                            context.read<CartBloc>().add(RemoveFromCart(uniqueId));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Dihapus dari keranjang')),
                            );
                          } else {
                            context.read<CartBloc>().add(AddToCart(productToAdd));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Ditambahkan ke keranjang')),
                            );
                          }

                          setState(() {});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isInCart ? Colors.redAccent : Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(isInCart ? 'Hapus dari Keranjang' : 'Tambah ke Keranjang'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColorFromName(String name) {
    switch (name.toLowerCase()) {
      case 'merah':
        return Colors.red;
      case 'biru':
        return Colors.blue;
      case 'hitam':
        return Colors.black;
      case 'putih':
        return Colors.white;
      case 'kuning':
        return Colors.yellow;
      case 'hijau':
        return Colors.green;
      case 'hijau kuning':
      case 'hijau strip kuning':
        return Colors.lime;
      case 'transparan':
        return Colors.grey[200]!;
      default:
        return Colors.grey;
    }
  }

  bool _needsInnerBorder(String name) {
    final color = name.toLowerCase();
    return color == 'putih' || color.contains('kuning') || color == 'transparan';
  }
}
