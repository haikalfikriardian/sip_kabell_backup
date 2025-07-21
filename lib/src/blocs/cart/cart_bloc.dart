import 'package:flutter_bloc/flutter_bloc.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(const CartState()) {
    // Tambah produk ke keranjang
    on<AddToCart>((event, emit) {
      final updatedCart = List<Map<String, dynamic>>.from(state.cartItems)
        ..add(event.product);
      emit(CartState(cartItems: updatedCart));
    });

    // Hapus produk dari keranjang berdasarkan ID
    on<RemoveFromCart>((event, emit) {
      final updatedCart = state.cartItems
          .where((item) => item['id'] != event.productId)
          .toList();
      emit(CartState(cartItems: updatedCart));
    });

    // Kosongkan keranjang
    on<ClearCart>((event, emit) {
      emit(const CartState(cartItems: []));
    });
  }
}
