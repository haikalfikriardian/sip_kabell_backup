import 'package:flutter_bloc/flutter_bloc.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(const CartState()) {
    // Tambah ke keranjang
    on<AddToCart>((event, emit) {
      final updatedCart = List<Map<String, dynamic>>.from(state.cartItems)
        ..add(event.product);
      emit(state.copyWith(cartItems: updatedCart));
    });

    // Hapus dari keranjang berdasarkan kombinasi unik (id + color + panjang)
    on<RemoveFromCart>((event, emit) {
      final updatedCart = state.cartItems.where((item) {
        return !(_isSameItem(item, event.productId));
      }).toList();
      emit(state.copyWith(cartItems: updatedCart));
    });

    // Kosongkan keranjang
    on<ClearCart>((event, emit) {
      emit(state.copyWith(cartItems: []));
    });

    // Update kuantitas produk
    on<UpdateCartQuantity>((event, emit) {
      final updatedCart = state.cartItems.map((item) {
        if (_isSameItem(item, event.productId)) {
          return {
            ...item,
            'quantity': event.quantity,
          };
        }
        return item;
      }).toList();

      emit(state.copyWith(cartItems: updatedCart));
    });
  }

  /// Fungsi untuk membandingkan ID unik produk di keranjang
  bool _isSameItem(Map<String, dynamic> item, String targetId) {
    final itemId = '${item['id']}_${item['color']}_${item['panjang']}';
    return itemId == targetId;
  }
}
