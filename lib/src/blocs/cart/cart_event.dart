abstract class CartEvent {}

class AddToCart extends CartEvent {
  final Map<String, dynamic> product;
  AddToCart(this.product);
}

class RemoveFromCart extends CartEvent {
  final String productId;
  RemoveFromCart(this.productId);
}

class ClearCart extends CartEvent {}

class FetchCartItems extends CartEvent {}

class UpdateCartQuantity extends CartEvent {
  final String productId;
  final int quantity;

  UpdateCartQuantity(this.productId, this.quantity);
}
