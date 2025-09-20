import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String? type;
  final String? orderId;
  final String userId;
  final String userName;
  final DateTime createdAt;
  final List<String> readBy;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.userId,
    required this.userName,
    required this.createdAt,
    required this.readBy,
    this.type,
    this.orderId,
  });

  factory NotificationModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return NotificationModel(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: data['type'],
      orderId: data['orderId'],
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      readBy: List<String>.from(data['readBy'] ?? []),
    );
  }
}
