import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/shipping_zone_model.dart';
import '../utils/shipping_helper.dart';

class CheckShippingPage extends StatefulWidget {
  const CheckShippingPage({super.key});

  @override
  State<CheckShippingPage> createState() => _CheckShippingPageState();
}

class _CheckShippingPageState extends State<CheckShippingPage> {
  final _areaController = TextEditingController();
  final _lengthController = TextEditingController();
  final _typeController = TextEditingController();

  // ✅ Tambahan: list jenis kabel & state pilihan dropdown
  static const List<String> _kCableTypes = [
    'NYA','NYAF','NYLHY','NYM','NYMHY','NYY','NYYHY',
    'Kabel Power Chord','Kabel Setrika','Kabel Power',
    'Kabel Coaxial 3C-2V','Kabel Coaxial 5C-2V','Kabel Coaxial 7C-2V','Kabel Coaxial RG58',
    'Kabel Head','Kabel Microphone','Kabel RCA','Kabel Single','Kabel Transparan','Kabel CCTV',
  ];
  String? _selectedCableType;

  List<ShippingZoneModel> zones = [];
  ShippingZoneModel? selectedZone;

  double? estimatedOngkir;
  String? resultMessage;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchShippingZones();
  }

  Future<void> fetchShippingZones() async {
    final snapshot =
    await FirebaseFirestore.instance.collection('shipping_zones').get();
    final zoneList =
    snapshot.docs.map((doc) => ShippingZoneModel.fromDocument(doc)).toList();
    setState(() {
      zones = zoneList;
      if (zones.isNotEmpty) {
        selectedZone = zones.first;
      }
      // set default jenis kabel (opsional)
      _selectedCableType ??= _kCableTypes.first;
      _typeController.text = _selectedCableType ?? '';
    });
  }

  Future<void> calculateShippingCost() async {
    final inputArea =
    _areaController.text.trim().toLowerCase().replaceAll(',', '');
    final cableType = _typeController.text.trim().toLowerCase(); // tetap pakai controller
    final cableLength = double.tryParse(_lengthController.text.trim()) ?? 0;

    if (inputArea.isEmpty ||
        cableType.isEmpty ||
        cableLength <= 0 ||
        selectedZone == null) {
      setState(() {
        resultMessage = 'Mohon lengkapi semua data dengan benar.';
        estimatedOngkir = null;
      });
      return;
    }

    setState(() {
      isLoading = true;
      resultMessage = null;
    });

    try {
      String? matchedArea;

      for (var areaName in selectedZone!.areas) {
        final normalizedArea = areaName.toLowerCase().replaceAll(',', '');
        if (inputArea == normalizedArea) {
          matchedArea = areaName;
          break;
        }
      }

      if (matchedArea == null) {
        setState(() {
          estimatedOngkir = null;
          resultMessage =
          'Area tidak ditemukan dalam zona pengiriman gudang terpilih.';
        });
        return;
      }

      final isInSameCityAsWarehouse =
      inputArea.contains(selectedZone!.warehouseLocation.toLowerCase());
      final weightPerMeter = ShippingHelper.getWeightPerMeter(cableType);
      final baseRate = isInSameCityAsWarehouse
          ? selectedZone!.baseRate / 2
          : selectedZone!.baseRate;

      final ongkir = ShippingHelper.calculateOngkir(
        baseRate: baseRate,
        weightPerMeter: weightPerMeter,
        length: cableLength,
      );

      setState(() {
        estimatedOngkir = ongkir;
        resultMessage =
        'Estimasi ongkir ke "$matchedArea" dari gudang ${selectedZone!.warehouseLocation}:';
      });
    } catch (e) {
      setState(() {
        estimatedOngkir = null;
        resultMessage = 'Terjadi kesalahan saat menghitung ongkir.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _areaController.dispose();
    _lengthController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final formatter = NumberFormat.currency(locale: 'id', symbol: 'Rp');

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: theme.dividerColor.withOpacity(0.4),
      ),
    );

    final filledColor = theme.inputDecorationTheme.fillColor ??
        (theme.brightness == Brightness.dark
            ? Colors.white.withOpacity(0.06)
            : Colors.white);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Cek Ongkir',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor:
        theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
        foregroundColor: theme.appBarTheme.foregroundColor ?? cs.onSurface,
        elevation: 0,
      ),
      body: zones.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ✅ Card Input
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildLabel(context, 'Pilih Gudang'),
                  DropdownButtonFormField<ShippingZoneModel>(
                    value: selectedZone,
                    items: zones.map((zone) {
                      return DropdownMenuItem(
                        value: zone,
                        child: Text(zone.warehouseLocation),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedZone = value;
                      });
                    },
                    dropdownColor: theme.colorScheme.surface,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: cs.onSurface),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: filledColor,
                      border: inputBorder,
                      enabledBorder: inputBorder,
                      focusedBorder: inputBorder.copyWith(
                        borderSide: BorderSide(color: cs.primary),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildLabel(context, 'Area Tujuan'),
                  TextField(
                    controller: _areaController,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: cs.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Contoh: Purwokerto',
                      filled: true,
                      fillColor: filledColor,
                      border: inputBorder,
                      enabledBorder: inputBorder,
                      focusedBorder: inputBorder.copyWith(
                        borderSide: BorderSide(color: cs.primary),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildLabel(context, 'Jenis Kabel'),
                  // ✅ Ganti TextField -> DropdownButtonFormField
                  DropdownButtonFormField<String>(
                    value: _selectedCableType,
                    items: _kCableTypes
                        .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedCableType = val;
                        _typeController.text = val ?? ''; // sinkron ke controller
                      });
                    },
                    hint: const Text('Pilih jenis kabel'),
                    dropdownColor: theme.colorScheme.surface,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: cs.onSurface),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: filledColor,
                      border: inputBorder,
                      enabledBorder: inputBorder,
                      focusedBorder: inputBorder.copyWith(
                        borderSide: BorderSide(color: cs.primary),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildLabel(context, 'Panjang Kabel (meter)'),
                  TextField(
                    controller: _lengthController,
                    keyboardType: TextInputType.number,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: cs.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Contoh: 50',
                      filled: true,
                      fillColor: filledColor,
                      border: inputBorder,
                      enabledBorder: inputBorder,
                      focusedBorder: inputBorder.copyWith(
                        borderSide: BorderSide(color: cs.primary),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : calculateShippingCost,
                      icon: isLoading
                          ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                          : const Icon(Icons.calculate),
                      label: Text(
                          isLoading ? 'Menghitung...' : 'Hitung Ongkir'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        padding:
                        const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ✅ Card Hasil
            if (resultMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(resultMessage!,
                        style: theme.textTheme.bodyLarge),
                    if (estimatedOngkir != null)
                      Text(
                        formatter.format(estimatedOngkir),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: theme.brightness == Brightness.dark
                              ? cs.primary
                              : Colors.green,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
      ],
    );
  }
}
