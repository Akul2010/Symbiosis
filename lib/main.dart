import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const SymbiosisApp());
}

class SymbiosisApp extends StatelessWidget {
  const SymbiosisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Symbiosis Engine',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
