import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/banner_model.dart';

class BannerService {
  final _bannerRef = FirebaseFirestore.instance.collection('banners');

  Future<List<BannerModel>> fetchBanners() async {
    final snapshot = await _bannerRef.orderBy('createdAt', descending: true).get();
    return snapshot.docs
        .map((doc) => BannerModel.fromMap(doc.id, doc.data()))
        .toList();
  }
}
