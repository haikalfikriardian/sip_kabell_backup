import 'package:cloud_firestore/cloud_firestore.dart';

class BannerModel {
  final String id;
  final String imageUrl;
  final DateTime createdAt;

  BannerModel({
    required this.id,
    required this.imageUrl,
    required this.createdAt,
  });

  factory BannerModel.fromMap(String id, Map<String, dynamic> data) {
    return BannerModel(
      id: id,
      imageUrl: data['imageUrl'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
