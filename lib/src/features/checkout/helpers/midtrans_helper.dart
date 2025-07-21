import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String> createMidtransTransaction({
  required String orderId,
  required int grossAmount,
  required String customerName,
}) async {
  const serverKey = 'Mid-server-8GZE6S_jMK0kic1AOEDAGSVK'; // Ganti dengan server key sandbox kamu
  const String midtransUrl = 'https://app.sandbox.midtrans.com/snap/v1/transactions';

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
        "first_name": customerName,
      }
    }),
  );

  if (response.statusCode == 201) {
    final snapUrl = jsonDecode(response.body)['redirect_url'];
    return snapUrl;
  } else {
    throw Exception('Gagal membuat transaksi Midtrans: ${response.body}');
  }
}
