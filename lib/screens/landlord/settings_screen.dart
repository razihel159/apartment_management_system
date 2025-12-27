import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Settings", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 30),
        Card(
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.indigo, child: Icon(Icons.person, color: Colors.white)),
            title: const Text("Admin Account"),
            subtitle: const Text("admin@example.com"),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pushReplacementNamed('/'), 
            icon: const Icon(Icons.logout),
            label: const Text("Logout"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[50], foregroundColor: Colors.red, padding: const EdgeInsets.all(20)),
          ),
        ),
      ],
    );
  }
}