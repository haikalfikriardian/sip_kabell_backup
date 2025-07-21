import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/bloc/cart/cart_bloc.dart';
import '../../auth/bloc/cart/cart_event.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> productData;

  const ProductDetailPage({super.key, required this.productData});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  String? selectedColor;
  int? selectedLength;

  @override
  Widget build(BuildContext context) {
    final data = widget.productData;

    List<String> availableColors = List<String>.from(data['availableColors'] ?? []);
    List<int> availableLengths = List<int>.from(data['availableLengths'] ?? []);

    final productId = data['id'] ?? data['name']; // fallback ke name
    final cartItems = context.watch<CartBloc>().state.cartItems;
    final isInCart = cartItems.any((item) =>
    item['id'] == productId &&
        item['color'] == selectedColor &&
        item['length'] == selectedLength);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('Detail Produk', style: TextStyle(fontSize: 16)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar Produk
          Container(
            height: 220,
            color: Colors.grey[200],
            child: Center(
              child: Image.network(
                data['imageUrl'] ?? '',
                width: 150,
                height: 150,
                errorBuilder: (_, __, ___) =>
                const Icon(Icons.broken_image, size: 60),
              ),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama & Favorite
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          data['name'] ?? 'Nama Kabel',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.favorite_border),
                    ],
                  ),

                  const SizedBox(height: 6),
                  Text(
                    data['description'] ?? 'Deskripsi belum tersedia.',
                    style:
                    const TextStyle(fontSize: 13, color: Colors.black54),
                  ),

                  const SizedBox(height: 20),

                  const Text('Pilih Warna',
                      style: TextStyle(fontWeight: FontWeight.bold)),
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
                              color: isSelected
                                  ? Colors.black
                                  : Colors.grey.shade300,
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
                                border: Border.all(
                                    color: Colors.black, width: 1),
                              ),
                            ),
                          )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Panjang & Harga
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Dropdown panjang kabel
                      Container(
                        width: 130,
                        height: 42,
                        padding:
                        const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border:
                          Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<int>(
                          value: selectedLength,
                          hint: const Text('Panjang'),
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: availableLengths.map((length) {
                            return DropdownMenuItem(
                              value: length,
                              child: Text('$length M'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => selectedLength = value);
                          },
                        ),
                      ),
                      Text(
                        'Rp ${data['price'] ?? '0'}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Tombol Aksi
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (selectedColor == null ||
                            selectedLength == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                Text('Pilih warna dan panjang dulu')),
                          );
                          return;
                        }

                        final productToAdd = {
                          'id': productId,
                          'name': data['name'],
                          'imageUrl': data['imageUrl'],
                          'price': data['price'],
                          'color': selectedColor,
                          'length': selectedLength,
                        };

                        if (isInCart) {
                          context
                              .read<CartBloc>()
                              .add(RemoveFromCart(productId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Dihapus dari keranjang')),
                          );
                        } else {
                          context
                              .read<CartBloc>()
                              .add(AddToCart(productToAdd));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                Text('Ditambahkan ke keranjang')),
                          );
                        }

                        setState(() {}); // Refresh UI
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isInCart
                            ? Colors.redAccent
                            : Colors.orange,
                      ),
                      child: Text(
                          isInCart ? 'Hapus dari Keranjang' : 'Tambah ke Keranjang'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
    return color == 'putih' ||
        color.contains('kuning') ||
        color == 'transparan';
  }
}
