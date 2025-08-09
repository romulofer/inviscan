import 'package:flutter/material.dart';
import 'scan_screen.dart';
import 'settings_screen.dart';

import '../widgets/previous_scans_list.dart';

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
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => ScanScreen(domain: url)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _urlTextController,
              decoration: InputDecoration(
                labelText: 'Digite a url para iniciar o scan',
                helperText: 'https://',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: 'Limpar',
                  onPressed: () => _urlTextController.clear(),
                  icon: const Icon(Icons.clear),
                ),
              ),
              textInputAction: TextInputAction.go,
              onSubmitted: (_) => _iniciarScan(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _iniciarScan,
              child: const Text('Escanear'),
            ),
            const SizedBox(height: 12),
            const Expanded(child: PreviousScansList()),
          ],
        ),
      ),
    );
  }
}
