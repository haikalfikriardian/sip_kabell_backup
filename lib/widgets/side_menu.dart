// lib/widgets/side_menu.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SideMenu extends StatelessWidget {
  final VoidCallback onProfileTap;

  const SideMenu({
    Key? key,
    required this.onProfileTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),

            /// Header user
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user?.uid)
                    .get(),
                builder: (context, snapshot) {
                  final data = snapshot.data?.data() as Map<String, dynamic>?;
                  final name = data?['name']?.toString().trim();
                  final photoUrl = data?['photoUrl']?.toString();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Halo!",
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          Navigator.pop(context);
                          await Future.delayed(const Duration(milliseconds: 120));
                          if (context.mounted) onProfileTap();
                        },
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: theme.dividerColor.withOpacity(0.2),
                              backgroundImage:
                              (photoUrl != null && photoUrl.isNotEmpty)
                                  ? NetworkImage(photoUrl)
                                  : null,
                              child: (photoUrl == null || photoUrl.isEmpty)
                                  ? Icon(Icons.person,
                                  size: 28,
                                  color: cs.onSurface.withOpacity(0.7))
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name?.isNotEmpty == true
                                        ? name!
                                        : (user?.displayName ??
                                        user?.email ??
                                        'Pengguna'),
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    "Personal Info",
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: cs.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios,
                                size: 18, color: cs.onSurface.withOpacity(0.7)),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 24),
            Divider(color: theme.dividerColor, height: 1),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Settings",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            // Wishlist
            _MenuItem(
              icon: Icons.favorite,
              iconBg: Colors.orange.withOpacity(0.15),
              iconColor: Colors.orange,
              title: "Wishlist",
              onTap: () async {
                Navigator.pop(context);
                await Future.delayed(const Duration(milliseconds: 120));
                if (context.mounted) {
                  Navigator.pushNamed(context, '/wishlist');
                }
              },
            ),

            _MenuItem(
              icon: Icons.notifications,
              iconBg: Colors.orange.withOpacity(0.15),
              iconColor: Colors.orange,
              title: "Notifications",
              onTap: () async {
                Navigator.pop(context);
                await Future.delayed(const Duration(milliseconds: 120));
                if (context.mounted) {
                  Navigator.pushNamed(context, '/notifications');
                }
              },
            ),

            _MenuItem(
              icon: Icons.local_shipping,
              iconBg: Colors.orange.withOpacity(0.15),
              iconColor: Colors.orange,
              title: "Cek Ongkir",
              onTap: () async {
                Navigator.pop(context);
                await Future.delayed(const Duration(milliseconds: 120));
                if (context.mounted) {
                  Navigator.pushNamed(context, '/cek-ongkir');
                }
              },
            ),

            _MenuItem(
              icon: Icons.menu_book,
              iconBg: Colors.orange.withOpacity(0.15),
              iconColor: Colors.orange,
              title: "Download Catalog",
              onTap: () async {
                Navigator.pop(context);
                await Future.delayed(const Duration(milliseconds: 120));
                if (context.mounted) {
                  Navigator.pushNamed(context, '/catalog-download');
                }
              },
            ),

            // About
            _MenuItem(
              icon: Icons.info_outline,
              iconBg: cs.primary.withOpacity(0.08),
              iconColor: cs.primary,
              title: "About",
              onTap: () async {
                Navigator.pop(context);
                await Future.delayed(const Duration(milliseconds: 120));
                if (context.mounted) {
                  Navigator.pushNamed(context, '/about');
                }
              },
            ),

            const Spacer(),

            // Sign out
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange.withOpacity(0.15),
                child: const Icon(Icons.logout, color: Colors.orange),
              ),
              title: Text(
                "Sign Out",
                style: theme.textTheme.titleMedium?.copyWith(color: Colors.orange),
              ),
              trailing: Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: cs.onSurface.withOpacity(0.6)),
              onTap: () async {
                Navigator.of(context).pop(); // tutup drawer
                await FirebaseAuth.instance.signOut();
                await Future.delayed(const Duration(milliseconds: 150));
                if (context.mounted) {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/login', (route) => false);
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;

  const _MenuItem({
    Key? key,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconBg,
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title, style: theme.textTheme.titleMedium),
      trailing: Icon(Icons.arrow_forward_ios_rounded,
          size: 16, color: cs.onSurface.withOpacity(0.6)),
      onTap: onTap,
    );
  }
}
