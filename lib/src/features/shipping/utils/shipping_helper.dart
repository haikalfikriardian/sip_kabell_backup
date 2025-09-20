import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shipping_zone_model.dart';

class ShippingHelper {
  // ==== Utils ====
  static String _norm(String s) => s.toLowerCase().replaceAll(',', '').trim();
  static String _title(String s) {
    final t = s.trim();
    if (t.isEmpty) return t;
    return t[0].toUpperCase() + t.substring(1).toLowerCase();
  }

  /// Fallback berat per meter berdasarkan jenis kabel (kg/m).
  /// Hanya dipakai kalau item/cart tidak punya weightPerMeter.
  static double getWeightPerMeter(String cableType) {
    final s = cableType.toLowerCase().trim();
    switch (s) {
      case 'nya': return 0.015;
      case 'nyaf': return 0.016;
      case 'nylhy': return 0.030;
      case 'nym': return 0.120;      // mendekati 0.1216
      case 'nymhy': return 0.090;
      case 'nyy': return 0.250;
      case 'nyyhy': return 0.200;

      case 'kabel power chord': return 0.060;
      case 'kabel setrika': return 0.070;
      case 'kabel power': return 0.080;

      case 'kabel coaxial 3c-2v': return 0.025;
      case 'kabel coaxial 5c-2v': return 0.045;
      case 'kabel coaxial 7c-2v': return 0.060;
      case 'kabel coaxial rg58': return 0.030;

      case 'kabel head': return 0.020;
      case 'kabel microphone': return 0.060;
      case 'kabel rca': return 0.040;
      case 'kabel single': return 0.020;
      case 'kabel transparan': return 0.040;
      case 'kabel cctv': return 0.080;
      default: return 0.050;
    }
  }

  /// Versi lama (tetap dipertahankan untuk halaman cek ongkir terpisah)
  static double calculateOngkir({
    required double baseRate,
    required double weightPerMeter,
    required double length,
  }) {
    final totalWeight = weightPerMeter * length; // kg
    return baseRate + (totalWeight * 1000);      // fallback 1000/kg
  }

  /// Cari zona cocok (pakai model `ShippingZoneModel`)
  static Future<ShippingZoneModel?> findMatchingShippingZone(String areaInput) async {
    final snapshot = await FirebaseFirestore.instance.collection('shipping_zones').get();
    final inputLower = _norm(areaInput);

    for (final doc in snapshot.docs) {
      final zone = ShippingZoneModel.fromDocument(doc);
      for (final zona in zone.areas) {
        if (_norm(zona) == inputLower) return zone;
      }
    }
    return null;
  }

  /// ===== Dipakai di Checkout: ongkir dinamis per kg =====
  ///
  /// Dokumen `shipping_zones/{zoneId}` yang dibaca:
  /// - baseCost: Number (wajib)
  /// - costPerKg: Number (opsional; fallback ke zoneCostPerKm)
  /// - sameCityDiscount: Number (opsional; %)
  /// - gudang / warehouseLocation: String
  /// - zona_tercover / areas: [String]
  ///
  /// Fallback urutan matching:
  /// 1) area ∈ zona_tercover/areas
  /// 2) doc id == TitleCase(area)  (mis. "Purwokerto")
  /// 3) doc id == "Purwokerto"     (DEFAULT_GUDANG)
  static const String DEFAULT_GUDANG = 'Purwokerto';

  static Future<double> calculateShipping({
    required String area,
    required double totalWeight,
  }) async {
    final areaNorm = _norm(area);
    if (areaNorm.isEmpty) return 0;

    final col = FirebaseFirestore.instance.collection('shipping_zones');
    final all = await col.get();

    Map<String, dynamic>? matched;

    // 1) match by coverage list
    for (final d in all.docs) {
      final data = d.data();
      final coversRaw = (data['zona_tercover'] as List<dynamic>?) ??
          (data['areas'] as List<dynamic>?) ?? const [];
      final covers = coversRaw.map((e) => _norm(e.toString())).toList();
      if (covers.contains(areaNorm)) {
        matched = data;
        break;
      }
    }

    // 2) match by doc id (TitleCase)
    if (matched == null) {
      final tryId = _title(areaNorm);
      final doc = await col.doc(tryId).get();
      if (doc.exists) matched = doc.data();
    }

    // 3) fallback ke default gudang
    if (matched == null) {
      final doc = await col.doc(DEFAULT_GUDANG).get();
      if (doc.exists) matched = doc.data();
    }

    if (matched == null) return 0;

    // ==== Tarif ====
    final baseCost = (matched['baseCost'] is num)
        ? (matched['baseCost'] as num).toDouble()
        : 0.0;

    final costPerKg = (matched['costPerKg'] is num)
        ? (matched['costPerKg'] as num).toDouble()
        : ((matched['zoneCostPerKm'] is num)
        ? (matched['zoneCostPerKm'] as num).toDouble()
        : 0.0);

    final sameCityDiscount = (matched['sameCityDiscount'] is num)
        ? (matched['sameCityDiscount'] as num).toDouble()
        : 0.0;

    final gudangName =
    (matched['gudang'] ?? matched['warehouseLocation'] ?? '').toString();

    // Diskon base cost jika same-city
    double effectiveBase = baseCost;
    if (_norm(gudangName) == areaNorm && sameCityDiscount > 0) {
      effectiveBase = baseCost * (1 - (sameCityDiscount / 100.0));
    }

    // Berat kena tagih (kalau 0, tetap charge base cost)
    final chargeableKg = totalWeight > 0 ? totalWeight.ceilToDouble() : 0.0;

    final shipping = effectiveBase + (chargeableKg * costPerKg);

    // Pastikan tidak negatif
    return shipping < 0 ? 0 : shipping;
  }
}
