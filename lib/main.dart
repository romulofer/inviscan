import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const Inviscan());
}

class Inviscan extends StatelessWidget {
  const Inviscan({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inviscan',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const HomeScreen(),
    );
  }
}
