import 'package:flutter/material.dart';
import 'scan_screen.dart';
import 'settings_screen.dart';

import '../l10n/app_localizations.dart';
import '../utils/input_validation.dart';
import '../widgets/previous_scans_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _urlTextController = TextEditingController();

  void _iniciarScan() {
    final raw = _urlTextController.text.trim();
    if (raw.isEmpty) return;

    // Valida/normaliza antes de navegar para dar feedback imediato, em vez de
    // falhar no meio do scan. O ScanService revalida por garantia.
    final String domain;
    try {
      domain = validateAndNormalizeDomain(raw);
    } on ArgumentError catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${e.message}')),
      );
      return;
    }

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ScanScreen(domain: domain)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeTitle, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: l10n.settingsTitle,
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
                labelText: l10n.scanUrlLabel,
                helperText: 'https://',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: l10n.clearField,
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
              child: Text(l10n.scanButton),
            ),
            const SizedBox(height: 12),
            const Expanded(child: PreviousScansList()),
          ],
        ),
      ),
    );
  }
}
