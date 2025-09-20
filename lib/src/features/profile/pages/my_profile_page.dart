// lib/src/features/profile/pages/my_profile_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../theme/theme_cubit.dart';

class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  final user = FirebaseAuth.instance.currentUser;
  String? photoUrl;
  String userName = '';
  bool isDarkMode = false; // lokal, disinkron saat toggle

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user?.uid)
        .get();
    final data = doc.data();

    if (data != null) {
      setState(() {
        photoUrl = data['photoUrl'];
        userName = data['name'] ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final bool isDark = context.watch<ThemeCubit>().state == ThemeMode.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // ✅ Back: pop jika bisa, kalau tidak arahkan ke '/home'
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.onSurface),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/home', (route) => false);
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          children: [
            Text(
              "Profile",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Photo",
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),

            CircleAvatar(
              radius: 48,
              backgroundColor: theme.dividerColor.withOpacity(0.2),
              backgroundImage:
              photoUrl != null ? NetworkImage(photoUrl!) : null,
              child: photoUrl == null
                  ? Icon(Icons.person,
                  size: 48, color: colors.onSurface.withOpacity(0.6))
                  : null,
            ),

            const SizedBox(height: 24),

            _buildMenuItem(
              context,
              icon: Icons.edit,
              label: "Edit Profile",
              onTap: () => Navigator.pushNamed(context, '/edit-profile'),
            ),

            // Dark Mode Toggle
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: _leadingIconBox(context, Icons.dark_mode),
                title: const Text("Dark Mode"),
                trailing: Switch(
                  value: isDark,
                  activeColor: Colors.white,
                  activeTrackColor: Colors.orange,
                  inactiveThumbColor: colors.onSurface,
                  inactiveTrackColor: theme.dividerColor.withOpacity(0.6),
                  onChanged: (val) {
                    context.read<ThemeCubit>().toggleDark(val);
                    setState(() => isDarkMode = val);
                  },
                ),
              ),
            ),

            _buildMenuItem(
              context,
              icon: Icons.location_on,
              label: "Alamat Rumah",
              onTap: () => Navigator.pushNamed(context, '/edit-address'),
            ),

            _buildMenuItem(
              context,
              icon: Icons.lock_reset,
              label: "Reset Password",
              onTap: () => Navigator.pushNamed(context, '/forgot-password'),
            ),

            const Spacer(),

            // Tombol Simpan
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Perubahan disimpan')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Simpan",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ==== Widgets util ====

  Widget _buildMenuItem(
      BuildContext context, {
        required IconData icon,
        required String label,
        required VoidCallback onTap,
      }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: _leadingIconBox(context, icon),
        title: Text(label),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _leadingIconBox(BuildContext context, IconData icon) {
    final theme = Theme.of(context);
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(
          theme.brightness == Brightness.dark ? 0.25 : 0.15,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: Colors.orange, size: 20),
    );
  }
}
