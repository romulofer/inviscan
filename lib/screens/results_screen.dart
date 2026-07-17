import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../l10n/app_localizations.dart';

class ResultsScreen extends StatelessWidget {
  final Set<String> allSubdomains;
  final List<String> activeSubdomains;
  final List<String> juicyTargets;

  const ResultsScreen({
    super.key,
    required this.allSubdomains,
    required this.activeSubdomains,
    required this.juicyTargets,
  });

  Future<void> _exportResults(BuildContext context) async {
    final results = {
      'total_subdomains': allSubdomains.length,
      'active_subdomains': activeSubdomains,
      'juicy_targets': juicyTargets,
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(results);

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
        '${dir.path}/scan_results_${DateTime.now().millisecondsSinceEpoch}.json',
      );
      await file.writeAsString(jsonString);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).resultsExportedTo(file.path)),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).exportResultsError(e)),
        ),
      );
    }
  }

  Widget _buildSection(BuildContext context, String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).sectionWithCount(title, items.length),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder:
                (_, index) => ListTile(
                  title: Text(
                    items[index],
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final subdomains = allSubdomains.toList()..sort();
    final active = activeSubdomains.toList()..sort();
    final juicy = juicyTargets.toList()..sort();

    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.resultsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _exportResults(context),
            tooltip: l10n.exportJson,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _buildSection(context, l10n.subdomainsFoundSection, subdomains),
            _buildSection(context, l10n.activeSubdomainsSection, active),
            _buildSection(context, l10n.juicyTargetsSection, juicy),
          ],
        ),
      ),
    );
  }
}
