import 'package:equatable/equatable.dart';

class CartState extends Equatable {
  final List<Map<String, dynamic>> cartItems;

  const CartState({this.cartItems = const []});

  @override
  List<Object> get props => [cartItems];
}
