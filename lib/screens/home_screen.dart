import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _urlTextController = TextEditingController();

  void _iniciarScan() {
    final url = _urlTextController.text.trim().replaceFirst(
      RegExp(r'^(https?:\/\/)?(www\.)?'),
      '',
    );
    if (url.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Você digitou a url: $url'),
          duration: const Duration(seconds: 2),
        ),
      );
      _urlTextController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: _urlTextController,
              decoration: const InputDecoration(
                labelText: 'Digite a url para iniciar o scan',
                helperText: 'https://',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _iniciarScan,
              child: const Text('Escanear'),
            ),
          ],
        ),
      ),
    );
  }
}
