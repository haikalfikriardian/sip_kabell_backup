import 'package:equatable/equatable.dart';

class CartState extends Equatable {
  final List<Map<String, dynamic>> cartItems;

  const CartState({this.cartItems = const []});

  // Tambahkan copyWith agar bisa update sebagian data
  CartState copyWith({
    List<Map<String, dynamic>>? cartItems,
  }) {
    return CartState(
      cartItems: cartItems ?? this.cartItems,
    );
  }

  @override
  List<Object> get props => [cartItems];
}
