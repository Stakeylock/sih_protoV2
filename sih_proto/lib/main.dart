import 'package:flutter/material.dart';
import 'screens/auth_screens.dart';

void main() {
  runApp(const SihProtoApp());
}

class SihProtoApp extends StatelessWidget {
  const SihProtoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIH Proto',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
      },
    );
  }
}