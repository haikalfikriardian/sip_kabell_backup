import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EditAddressPage extends StatefulWidget {
  const EditAddressPage({super.key});

  @override
  State<EditAddressPage> createState() => _EditAddressPageState();
}

class _EditAddressPageState extends State<EditAddressPage> {
  final user = FirebaseAuth.instance.currentUser;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _teleponController = TextEditingController();
  final TextEditingController _provinsiKotaController = TextEditingController();
  final TextEditingController _jalanController = TextEditingController();
  final TextEditingController _kodePosController = TextEditingController();

  String tipeAlamat = 'Toko';
  bool isPrimary = false;
  String? _editingAddressId; // null = create, not null = update

  @override
  void initState() {
    super.initState();
    _loadAlamatLama();
  }

  CollectionReference<Map<String, dynamic>> get _addrCol => FirebaseFirestore
      .instance
      .collection('users')
      .doc(user!.uid)
      .collection('addresses');

  Future<void> _loadAlamatLama() async {
    try {
      // prioritaskan alamat utama
      final primaryQ = await _addrCol.where('isPrimary', isEqualTo: true).limit(1).get();
      DocumentSnapshot<Map<String, dynamic>>? doc;
      if (primaryQ.docs.isNotEmpty) {
        doc = primaryQ.docs.first;
      } else {
        final anyQ = await _addrCol.limit(1).get();
        if (anyQ.docs.isNotEmpty) doc = anyQ.docs.first;
      }

      if (doc != null && doc.data() != null) {
        final data = doc.data()!;
        _editingAddressId = doc.id;
        _alamatController.text = data['alamat'] ?? '';
        _teleponController.text = data['telepon'] ?? '';
        _provinsiKotaController.text = data['provinsiKota'] ?? '';
        _jalanController.text = data['jalan'] ?? '';
        _kodePosController.text = data['kodePos'] ?? '';
        tipeAlamat = data['tipeAlamat'] ?? 'Toko';
        isPrimary = data['isPrimary'] ?? false;
        setState(() {});
      }
    } catch (_) {/* silent */}
  }

  Future<void> _simpanAlamat() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // apakah user sudah punya alamat?
      final existing = await _addrCol.limit(1).get();
      final shouldBePrimary = isPrimary || existing.docs.isEmpty;

      // jika akan dijadikan utama → unset yang lain
      if (shouldBePrimary) {
        final all = await _addrCol.get();
        final batch = FirebaseFirestore.instance.batch();
        for (final d in all.docs) {
          batch.update(d.reference, {'isPrimary': false});
        }
        await batch.commit();
      }

      final data = <String, dynamic>{
        'alamat': _alamatController.text.trim(),
        'telepon': _teleponController.text.trim(),
        'provinsiKota': _provinsiKotaController.text.trim(),
        'jalan': _jalanController.text.trim(),
        'kodePos': _kodePosController.text.trim(),
        'tipeAlamat': tipeAlamat,
        'isPrimary': shouldBePrimary,
        'userId': user!.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_editingAddressId != null) {
        await _addrCol.doc(_editingAddressId).set(data, SetOptions(merge: true));
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
        final ref = await _addrCol.add(data);
        _editingAddressId = ref.id;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alamat berhasil disimpan')),
        );
        Navigator.pop(context, true); // penting: agar Checkout reload
      }
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan alamat: ${e.message ?? e.code}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Edit Alamat Pengiriman",
          style: theme.textTheme.titleMedium?.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor ?? Colors.transparent,
        elevation: 0,
        leading: BackButton(color: cs.onSurface),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildLabel(context, "Alamat"),
              _buildInput(_alamatController),
              _buildLabel(context, "Nomor Telepon"),
              _buildInput(_teleponController),
              _buildLabel(context, "Provinsi, Kota, Kecamatan"),
              _buildInput(_provinsiKotaController),
              _buildLabel(context, "Nama Jalan, No. Rumah"),
              _buildInput(_jalanController),
              _buildLabel(context, "Kode Pos"),
              Row(
                children: [
                  Expanded(child: _buildInput(_kodePosController)),
                  const SizedBox(width: 12),
                  _buildTipeButton("Toko"),
                  const SizedBox(width: 8),
                  _buildTipeButton("Rumah"),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text("Atur Sebagai Alamat Utama",
                      style: theme.textTheme.bodyMedium),
                  const Spacer(),
                  Switch(
                    value: isPrimary,
                    onChanged: (val) => setState(() => isPrimary = val),
                    activeColor: cs.onPrimary,
                    activeTrackColor: cs.primary,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _simpanAlamat,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Simpan"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 16),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInput(TextEditingController controller) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final fill = theme.inputDecorationTheme.fillColor ??
        (isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200);

    return TextFormField(
      controller: controller,
      validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
      style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface),
      decoration: InputDecoration(
        filled: true,
        fillColor: fill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildTipeButton(String label) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isSelected = tipeAlamat == label;

    final bg = isSelected ? cs.primary : (theme.colorScheme.surfaceVariant);
    final fg = isSelected ? cs.onPrimary : cs.onSurface;

    return Expanded(
      child: ElevatedButton(
        onPressed: () => setState(() => tipeAlamat = label),
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: Text(label),
      ),
    );
  }
}
