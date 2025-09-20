import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';

import '../../../blocs/cart/cart_bloc.dart';
import '../../../blocs/cart/cart_event.dart';
import '../../../blocs/cart/cart_state.dart';
import '../../checkout/pages/checkout_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  Set<String> selectedItemIds = {};
  Map<String, int> itemQuantities = {};

  // ✅ peredam error “Dismissible still part of the tree”
  final Set<String> _pendingRemove = {};

  @override
  void initState() {
    super.initState();
    context.read<CartBloc>().add(FetchCartItems());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: cs.onSurface),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Keranjang', style: TextStyle(color: cs.onSurface)),
            BlocBuilder<CartBloc, CartState>(
              builder: (context, state) {
                return Text(
                  "${state.cartItems.length} items",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(.7),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          // filter item yang sedang dihapus agar langsung hilang dari tree
          final visibleItems = state.cartItems
              .where((it) => !_pendingRemove.contains(it['id']))
              .toList();

          if (visibleItems.isEmpty) {
            return Center(
              child: Text('Keranjang kosong',
                  style: TextStyle(color: cs.onSurface)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 140),
            itemCount: visibleItems.length,
            itemBuilder: (context, index) {
              final item = visibleItems[index];
              final id = item['id'].toString();
              final isSelected = selectedItemIds.contains(id);
              final quantity = (item['quantity'] ?? 1) as int;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Dismissible(
                  key: ValueKey(id),
                  direction: DismissDirection.endToStart,

                  // biar animasi selesai rapi dulu
                  confirmDismiss: (direction) async => true,

                  onDismissed: (_) async {
                    // tandai sedang dihapus -> langsung hilang dari list builder
                    setState(() => _pendingRemove.add(id));

                    // sinkron ke BLoC
                    context.read<CartBloc>().add(RemoveFromCart(id));

                    // bersihkan state lokal
                    setState(() {
                      selectedItemIds.remove(id);
                      itemQuantities.remove(id);
                    });

                    // opsional: lepas penanda jika BLoC sudah mengosongkan state
                    // (aman dibiarkan juga, karena item takkan muncul lagi)
                    await Future.delayed(const Duration(milliseconds: 300));
                    if (mounted) {
                      setState(() => _pendingRemove.remove(id));
                    }
                  },

                  background: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: cs.errorContainer
                          .withOpacity(isDark ? .35 : 1.0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Spacer(),
                        Icon(Iconsax.trash, color: cs.error, size: 26),
                      ],
                    ),
                  ),

                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withOpacity(.5)
                              : Colors.black12,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Checkbox
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Transform.scale(
                            scale: 1.05,
                            child: Checkbox(
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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              fillColor: MaterialStateProperty.resolveWith(
                                    (states) => states.contains(
                                    MaterialState.selected)
                                    ? cs.primary
                                    : theme.dividerColor,
                              ),
                              checkColor: cs.onPrimary,
                            ),
                          ),
                        ),

                        // Gambar
                        SizedBox(
                          width: 88,
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                (item['imageUrl'] ?? '').toString(),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: theme.dividerColor.withOpacity(.12),
                                  child: Icon(Icons.broken_image,
                                      color: cs.onSurface.withOpacity(.6)),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (item['name'] ?? '').toString(),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              if ((item['category'] ?? '').toString().isNotEmpty)
                                Text(
                                  (item['category'] ?? '').toString(),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: cs.onSurface.withOpacity(.6),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    "Rp ${(item['totalPrice'] ?? 0)}",
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: cs.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    "  x$quantity",
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: cs.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Qty + delete
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: () {
                                // tampilkan animasi swipe manual: langsung remove
                                setState(() => _pendingRemove.add(id));
                                context
                                    .read<CartBloc>()
                                    .add(RemoveFromCart(id));
                                setState(() => selectedItemIds.remove(id));
                              },
                              icon: Icon(Iconsax.trash,
                                  color: cs.onSurface.withOpacity(.6), size: 22),
                              tooltip: 'Hapus',
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: theme.dividerColor),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _QtyButton(
                                    icon: Icons.remove,
                                    onPressed: () {
                                      if (quantity > 1) {
                                        context.read<CartBloc>().add(
                                            UpdateCartQuantity(id, quantity - 1));
                                      }
                                    },
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    child: Text(
                                      '$quantity',
                                      style:
                                      theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                  ),
                                  _QtyButton(
                                    icon: Icons.add,
                                    onPressed: () {
                                      context.read<CartBloc>().add(
                                          UpdateCartQuantity(id, quantity + 1));
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),

      // Bottom summary (voucher row DIHILANGKAN)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, -15),
              blurRadius: 20,
              color: isDark
                  ? Colors.black.withOpacity(.45)
                  : const Color(0xFFDADADA).withOpacity(.25),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(child: _buildTotalInfo(context)),
              Expanded(
                child: BlocBuilder<CartBloc, CartState>(
                  builder: (context, state) {
                    final items = state.cartItems;
                    return ElevatedButton(
                      onPressed: selectedItemIds.isEmpty
                          ? null
                          : () => _goToCheckoutPage(context, items),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        minimumSize: const Size(double.infinity, 48),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                      ),
                      child: const Text("Continue to Checkout"),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalInfo(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final total = _calculateSelectedTotal();
    return Text.rich(
      TextSpan(
        text: "Total:\n",
        style: theme.textTheme.bodySmall?.copyWith(
          color: cs.onSurface.withOpacity(.7),
        ),
        children: [
          TextSpan(
            text: "Rp $total",
            style: theme.textTheme.titleMedium?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  int _calculateSelectedTotal() {
    final items = context.read<CartBloc>().state.cartItems;
    int total = 0;
    for (var item in items) {
      final id = item['id'];
      if (selectedItemIds.contains(id)) {
        final qty = ((item['quantity'] ?? 1) as num).toInt();
        final price = ((item['totalPrice'] ?? 0) as num).toInt();
        total += price * qty;
      }
    }
    return total;
  }

  void _goToCheckoutPage(
      BuildContext context, List<Map<String, dynamic>> items) {
    final selectedItems = items
        .where((item) => selectedItemIds.contains(item['id']))
        .map((item) {
      return {
        ...item,
        'productId': item['productId'] ?? item['id'], // fallback ke id
        'panjang': item['panjang'] ?? 1, // default 1 meter kalau kosong
        'quantity': item['quantity'] ?? 1,
      };
    }).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<CartBloc>(),
          child: CheckoutPage(selectedItems: selectedItems),
        ),
      ),
    );
  }

}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _QtyButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 28,
      height: 28,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onPressed,
          child: Center(
            child: Icon(icon, size: 16, color: cs.onSurface),
          ),
        ),
      ),
    );
  }
}
