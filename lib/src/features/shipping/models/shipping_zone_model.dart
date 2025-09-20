import 'package:cloud_firestore/cloud_firestore.dart';

class ShippingZoneModel {
  final String id;

  /// Nama kota gudang, contoh: "Purwokerto"
  final String warehouseLocation;

  /// Daftar area yang ter-cover oleh gudang ini
  final List<String> areas;

  /// Base charge zona (dokumen: baseCost)
  /// NB: kita tetap pakai nama properti `baseRate` supaya tidak memecah kode lama.
  final double baseRate;

  /// Tarif per kilogram (dokumen: costPerKg; fallback ke zoneCostPerKm)
  final double costPerKg;

  /// Diskon base untuk same-city (%), opsional
  final double sameCityDiscount;

  ShippingZoneModel({
    required this.id,
    required this.warehouseLocation,
    required this.areas,
    required this.baseRate,
    required this.costPerKg,
    this.sameCityDiscount = 0,
  });

  static double _toDouble(dynamic v) =>
      (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0.0;

  factory ShippingZoneModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // kompatibel: gudang / warehouseLocation
    final wl = (data['gudang'] ?? data['warehouseLocation'] ?? '').toString();

    // kompatibel: zona_tercover / areas
    final List<String> cover = (data['zona_tercover'] as List? ??
        data['areas'] as List? ??
        const [])
        .map((e) => e.toString())
        .toList();

    // baseCost -> baseRate
    final base = _toDouble(data['baseCost']);

    // costPerKg prioritas; fallback ke zoneCostPerKm (biar cocok dg struktur lama kamu)
    final cpk = data.containsKey('costPerKg')
        ? _toDouble(data['costPerKg'])
        : _toDouble(data['zoneCostPerKm']);

    final scd = _toDouble(data['sameCityDiscount']); // boleh 0 kalau tidak ada

    return ShippingZoneModel(
      id: doc.id,
      warehouseLocation: wl,
      areas: cover,
      baseRate: base,
      costPerKg: cpk,
      sameCityDiscount: scd,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // tulis dengan kunci yang dipakai di Firestore
      'gudang': warehouseLocation,
      'zona_tercover': areas,
      'baseCost': baseRate,
      'costPerKg': costPerKg,
      // TULISKAN JUGA zoneCostPerKm untuk kompatibilitas (opsional)
      'zoneCostPerKm': costPerKg,
      if (sameCityDiscount > 0) 'sameCityDiscount': sameCityDiscount,
    };
  }

  // ---- OPSIONAL: alias agar kode lama yang masih pakai `pricePerKg` tetap aman ----
  double get pricePerKg => costPerKg;
}
