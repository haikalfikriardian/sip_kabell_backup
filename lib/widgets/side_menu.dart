import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        children: [
          const SizedBox(height: 40),
          const Text('Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          const ListTile(
            leading: Icon(Icons.person),
            title: Text('Account'),
            subtitle: Text('Personal Info'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
          ),

          const SizedBox(height: 10),

          const ListTile(
            leading: Icon(Icons.language),
            title: Text('Language'),
            subtitle: Text('English'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
          ),
          const ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Notifications'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
          ),
          const ListTile(
            leading: Icon(Icons.dark_mode),
            title: Text('Dark Mode'),
            trailing: Switch(value: false, onChanged: null),
          ),
          const ListTile(
            leading: Icon(Icons.help),
            title: Text('Help'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.orange),
            title: const Text('Sign Out', style: TextStyle(color: Colors.orange)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              }
            },
          ),
        ],
      ),
    );
  }
}
