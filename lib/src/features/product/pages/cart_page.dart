import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sip_kabell_app/src/features/checkout/helpers/midtrans_helper.dart';

import '../../auth/bloc/cart/cart_bloc.dart';
import '../../auth/bloc/cart/cart_event.dart';
import '../../auth/bloc/cart/cart_state.dart';
import '../../checkout/pages/payment_webview_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  Set<String> selectedItemIds = {};
  Map<String, int> itemQuantities = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.black),
        title: const Text('Keranjang', style: TextStyle(color: Colors.black)),
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          final items = state.cartItems;

          if (items.isEmpty) {
            return const Center(child: Text('Keranjang kosong'));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final id = item['id'];
                    final isSelected = selectedItemIds.contains(id);
                    final quantity = item['quantity'] ?? 1;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        Checkbox(
                        value: isSelected,
                        onChanged: (_) {
                          setState(() {
                            if (isSelected) {
                              selectedItemIds.remove(id);
                            } else {
                              selectedItemIds.add(id);
                              itemQuantities[id] = quantity;
                            }
                          });
                        },
                        activeColor: Colors.orange,
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          item['imageUrl'] ?? '',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), // ✅ Diperbesar
                            ),
                            Text(
                              item['category'] ?? '',
                              style: const TextStyle(color: Colors.grey, fontSize: 13), // ✅ Kategori kabel muncul
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rp ${item['price'] ?? '0'}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () {
                              context.read<CartBloc>().add(RemoveFromCart(id));
                            },
                            icon: const Icon(Icons.delete, color: Colors.orange),
                          ),
                          Row(
                            children: [
                              _QtyButton(
                                icon: Icons.remove,
                                onPressed: () {
                                  if (quantity > 1) {
                                    context.read<CartBloc>().add(UpdateCartQuantity(id, quantity - 1));
                                  }
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text('$quantity', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              _QtyButton(
                                icon: Icons.add,
                                onPressed: () {
                                  context.read<CartBloc>().add(UpdateCartQuantity(id, quantity + 1));
                                },
                              ),
                            ],
                          ),

                              ],
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // TOTAL SECTION
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTotalInfo(),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: selectedItemIds.isEmpty ? null : () => _checkoutSelectedItems(context, items),
                        child: const Text("Continue to Payment", style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTotalInfo() {
    final total = _calculateSelectedTotal();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Subtotal", style: TextStyle(fontSize: 16)),
        Text("Rp ${total.toString()}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  int _calculateSelectedTotal() {
    final items = context.read<CartBloc>().state.cartItems;
    int total = 0;

    for (var item in items) {
      final id = item['id'];
      if (selectedItemIds.contains(id)) {
        final qty = item['quantity'] ?? 1;
        final price = (item['price'] as num?)?.toInt() ?? 0;
        total += (price * qty).toInt();
      }
    }

    return total;
  }


  Future<void> _checkoutSelectedItems(BuildContext context, List<Map<String, dynamic>> items) async {
    final selectedItems = items.where((item) => selectedItemIds.contains(item['id'])).toList();

    if (selectedItems.isEmpty) return;

    final addressController = TextEditingController();
    final address = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Alamat Pengiriman"),
        content: TextField(
          controller: addressController,
          decoration: const InputDecoration(hintText: "Contoh: Jl. Mawar No. 123"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, null), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, addressController.text),
            child: const Text("Lanjut"),
          ),
        ],
      ),
    );

    if (address == null || address.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kamu belum login.")),
      );
      return;
    }

    try {
      final total = _calculateSelectedTotal();
      final itemsToSave = selectedItems.map((item) {
        final id = item['id'];
        return {
          ...item,
          'quantity': itemQuantities[id] ?? 1,
        };
      }).toList();

      final orderRef = await FirebaseFirestore.instance.collection('orders').add({
        'userId': user.uid,
        'userName': user.displayName ?? user.email ?? 'User Tanpa Nama',
        'userAddress': address,
        'status': 'Menunggu Pembayaran',
        'createdAt': FieldValue.serverTimestamp(),
        'items': itemsToSave,
      });

      final snapUrl = await createMidtransTransaction(
        orderId: orderRef.id,
        grossAmount: total,
        customerName: user.displayName ?? user.email ?? 'User',
      );

      for (var item in selectedItems) {
        context.read<CartBloc>().add(RemoveFromCart(item['id']));
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentWebViewPage(
            url: snapUrl,
            orderId: orderRef.id,
            totalAmount: total,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Checkout gagal: $e")),
      );
    }
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _QtyButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: IconButton(
        icon: Icon(icon, size: 16),
        padding: EdgeInsets.zero,
        onPressed: onPressed,
      ),
    );
  }
}
