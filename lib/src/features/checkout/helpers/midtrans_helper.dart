import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

/// Fungsi untuk membuat transaksi Midtrans + simpan data pesanan ke Firestore
Future<Map<String, dynamic>> createMidtransTransaction({
  required String userId,
  required String userName,
  required String userAddress,
  required List<Map<String, dynamic>> items,
  required int grossAmount,
  required int shippingCost,
}) async {
  const serverKey = 'Mid-server-8GZE6S_jMK0kic1AOEDAGSVK';
  const String midtransUrl = 'https://app.sandbox.midtrans.com/snap/v1/transactions';

  final orderRef = FirebaseFirestore.instance.collection('orders').doc();
  final orderId = orderRef.id;

  final subtotal = grossAmount - shippingCost;

  await orderRef.set({
    'orderId': orderId,
    'userId': userId,
    'userName': userName,
    'userAddress': userAddress,
    'status': 'Menunggu Pembayaran',
    'createdAt': FieldValue.serverTimestamp(),
    'items': items,
    'subtotal': subtotal,
    'shippingCost': shippingCost,
    'grossAmount': grossAmount,
  });

  final response = await http.post(
    Uri.parse(midtransUrl),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Basic ${base64Encode(utf8.encode('$serverKey:'))}',
    },
    body: jsonEncode({
      "transaction_details": {
        "order_id": orderId,
        "gross_amount": grossAmount,
      },
      "customer_details": {
        "first_name": userName,
        "email": "dummy@email.com",
        "billing_address": {
          "address": userAddress,
        }
      },
      "enabled_payments": ["gopay", "bank_transfer", "shopeepay"],
    }),
  );

  if (response.statusCode == 201) {
    final snapUrl = jsonDecode(response.body)['redirect_url'];
    return {
      'orderId': orderId,
      'snapUrl': snapUrl,
    };
  } else {
    throw Exception('Gagal membuat transaksi Midtrans: ${response.body}');
  }
}
