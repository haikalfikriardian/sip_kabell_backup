import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class SideMenu extends StatelessWidget {
  final VoidCallback onProfileTap;

  const SideMenu({
    Key? key,
    required this.onProfileTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Halo!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.grey,
                        child: Icon(Iconsax.user, size: 28, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user?.displayName ?? 'Nama User',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const Text("Personal Info", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Iconsax.arrow_right_3, size: 20),
                        onPressed: onProfileTap,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Divider(height: 1),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Settings", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),

            _buildMenuItem(
              icon: Iconsax.heart5,
              color: Colors.orange,
              title: "Wishlist",
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/wishlist');
              },
            ),

            // ✅ Menu Notifikasi dengan titik merah realtime
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .snapshots(),
              builder: (context, snapshot) {
                final userId = user?.uid;
                bool hasUnread = false;

                if (snapshot.hasData && userId != null) {
                  hasUnread = snapshot.data!.docs.any((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final readBy = List<String>.from(data['readBy'] ?? []);
                    return !readBy.contains(userId);
                  });
                }

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey.shade200,
                    child: Stack(
                      children: [
                        const Icon(Iconsax.notification5, color: Colors.orange),
                        if (hasUnread)
                          const Positioned(
                            right: 0,
                            top: 0,
                            child: CircleAvatar(
                              radius: 4,
                              backgroundColor: Colors.red,
                            ),
                          ),
                      ],
                    ),
                  ),
                  title: const Text("Notifications"),
                  trailing: const Icon(Iconsax.arrow_right_3, size: 16),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/notifications');
                  },
                );
              },
            ),

            _buildMenuItem(
              icon: Iconsax.document_download5,
              color: Colors.orange,
              title: "Download Catalog",
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/catalog-download');
              },
            ),
            _buildMenuItem(
              icon: Iconsax.info_circle5,
              color: Colors.black54,
              title: "About",
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/about');
              },
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                },
                child: Row(
                  children: const [
                    Icon(Iconsax.logout5, color: Colors.orange),
                    SizedBox(width: 10),
                    Text("Sign Out", style: TextStyle(color: Colors.orange)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey.shade200,
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      trailing: const Icon(Iconsax.arrow_right_3, size: 16),
      onTap: onTap,
    );
  }
}
