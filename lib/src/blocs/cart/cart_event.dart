import 'package:equatable/equatable.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object> get props => [];
}

// Event: Tambah produk ke keranjang
class AddToCart extends CartEvent {
  final Map<String, dynamic> product;

  const AddToCart(this.product);

  @override
  List<Object> get props => [product];
}

// Event: Hapus produk dari keranjang berdasarkan ID
class RemoveFromCart extends CartEvent {
  final String productId;

  const RemoveFromCart(this.productId);

  @override
  List<Object> get props => [productId];
}

// Event: Kosongkan seluruh keranjang
class ClearCart extends CartEvent {
  const ClearCart();
}
