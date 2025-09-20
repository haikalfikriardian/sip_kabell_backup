import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(const CartState()) {
    on<AddToCart>((event, emit) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final cartRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cart');

        await cartRef.doc(event.product['id']).set(event.product);
      }

      final updatedCart = List<Map<String, dynamic>>.from(state.cartItems)
        ..add(event.product);
      emit(CartState(cartItems: updatedCart));
    });

    on<RemoveFromCart>((event, emit) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final cartRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cart');

        await cartRef.doc(event.productId).delete();
      }

      final updatedCart = state.cartItems
          .where((item) => item['id'] != event.productId)
          .toList();
      emit(CartState(cartItems: updatedCart));
    });

    on<ClearCart>((event, emit) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final cartRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cart');

        final cartItems = await cartRef.get();
        for (var doc in cartItems.docs) {
          await doc.reference.delete();
        }
      }

      emit(const CartState(cartItems: []));
    });

    on<FetchCartItems>((event, emit) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final cartRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cart');

        final cartSnapshot = await cartRef.get();
        final cartItems = cartSnapshot.docs.map((doc) => doc.data()).toList();

        emit(CartState(cartItems: cartItems));
      }
    });

    on<UpdateCartQuantity>((event, emit) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final cartRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cart');

        await cartRef.doc(event.productId).update({'quantity': event.quantity});
      }

      final updatedCart = state.cartItems.map((item) {
        if (item['id'] == event.productId) {
          return {...item, 'quantity': event.quantity};
        }
        return item;
      }).toList();

      emit(CartState(cartItems: updatedCart));
    });
  }
}
