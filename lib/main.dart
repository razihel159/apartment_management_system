import 'package:flutter/material.dart';
import 'screens/login_screen.dart'; // Import natin ang login screen

void main() {
  runApp(const ApartmentApp());
}

class ApartmentApp extends StatelessWidget {
  const ApartmentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Apartment Management System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      // Dito natin itatakda na LoginScreen ang unang lalabas
      home: const LoginScreen(),
    );
  }
}