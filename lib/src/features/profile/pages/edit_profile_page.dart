import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;

  String selectedGender = '';
  String? photoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(user?.uid).get();
    final data = doc.data();

    if (data != null) {
      nameController.text = data['name'] ?? '';
      selectedGender = data['gender'] ?? '';
      phoneController.text = data['phone'] ?? '';
      emailController.text = data['email'] ?? user?.email ?? '';
      photoUrl = data['photoUrl'];
    } else {
      emailController.text = user?.email ?? '';
    }

    setState(() {});
  }

  Future<void> _uploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      final file = File(picked.path);
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures/${user!.uid}.jpg');

      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final uploadTask = await storageRef.putFile(file, metadata);
      final url = await uploadTask.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'photoUrl': url,
      });

      setState(() {
        photoUrl = url;
      });
    }
  }

  Future<void> _saveProfile() async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(user?.uid).set({
        'name': nameController.text.trim(),
        'gender': selectedGender,
        'phone': phoneController.text.trim(),
        'email': emailController.text.trim(),
        'photoUrl': photoUrl ?? '',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profil berhasil disimpan")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menyimpan: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // warna field yang enak buat light/dark
    final fieldFill = theme.inputDecorationTheme.fillColor ??
        (isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Edit Profile",
          style: theme.textTheme.titleMedium?.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Foto Profil
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: theme.dividerColor.withOpacity(0.3),
                    backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
                    child: photoUrl == null
                        ? Icon(Icons.person, size: 48, color: cs.onSurface.withOpacity(0.5))
                        : null,
                  ),
                  IconButton(
                    tooltip: 'Ganti foto',
                    icon: Icon(Icons.camera_alt, color: cs.primary),
                    onPressed: _uploadImage,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text("Upload Foto",
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
              const SizedBox(height: 24),

              _buildTextField(context, "Nama", nameController, fill: fieldFill),
              const SizedBox(height: 16),
              _buildDropdownGender(context, fill: fieldFill),
              const SizedBox(height: 16),
              _buildTextField(context, "Nomor Telephone", phoneController, fill: fieldFill),
              const SizedBox(height: 16),
              _buildTextField(context, "Email", emailController, readOnly: true, fill: fieldFill),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Simpan", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      BuildContext context,
      String label,
      TextEditingController controller, {
        bool readOnly = false,
        required Color fill,
      }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: readOnly,
          style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface),
          decoration: InputDecoration(
            filled: true,
            fillColor: fill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownGender(BuildContext context, {required Color fill}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Jenis Kelamin", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: selectedGender.isEmpty ? null : selectedGender,
          items: const [
            DropdownMenuItem(value: 'Laki-laki', child: Text('Laki-laki')),
            DropdownMenuItem(value: 'Perempuan', child: Text('Perempuan')),
            DropdownMenuItem(value: 'Lainnya', child: Text('Lainnya')),
          ],
          onChanged: (value) {
            setState(() {
              selectedGender = value ?? '';
            });
          },
          dropdownColor: theme.cardColor,
          style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface),
          iconEnabledColor: cs.onSurface,
          decoration: InputDecoration(
            filled: true,
            fillColor: fill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
