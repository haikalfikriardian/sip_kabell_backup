import 'package:equatable/equatable.dart';

abstract class CartEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AddToCart extends CartEvent {
  final Map<String, dynamic> product;

  AddToCart(this.product);

  @override
  List<Object?> get props => [product];
}

class RemoveFromCart extends CartEvent {
  final String productId;

  RemoveFromCart(this.productId);

  @override
  List<Object?> get props => [productId];
}

class ClearCart extends CartEvent {}

class UpdateCartQuantity extends CartEvent {
  final String productId;
  final int quantity;

  UpdateCartQuantity(this.productId, this.quantity);

  @override
  List<Object?> get props => [productId, quantity];
}
