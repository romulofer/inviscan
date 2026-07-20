import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../l10n/app_localizations.dart';
import '../../utils/juicy_targets.dart';
import 'fs_helpers.dart';

class JuicyTargetsSection extends StatelessWidget {
  final Directory scanDir;
  const JuicyTargetsSection({super.key, required this.scanDir});

  Future<List<String>> _loadJuicyTargets() async {
    final jsonFile = File(p.join(scanDir.path, 'juicy_targets.json'));
    final txtFile = File(p.join(scanDir.path, 'juicy_targets.txt'));

    if (await jsonFile.exists()) {
      try {
        final data = json.decode(await jsonFile.readAsString());
        if (data is List) {
          return data.map((e) => e.toString()).toSet().toList()..sort();
        }
      } catch (_) {}
    }
    if (await txtFile.exists()) {
      final lines =
          (await txtFile.readAsLines())
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
      return lines;
    }

    final activeTxt = File(p.join(scanDir.path, 'active.txt'));
    if (await activeTxt.exists()) {
      final active =
          (await activeTxt.readAsLines())
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
      final deduced = identifyJuicyTargets(active);
      return deduced.toSet().toList()..sort();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<List<String>>(
      future: _loadJuicyTargets(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: LinearProgressIndicator(),
          );
        }
        final juicy = snap.data ?? [];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.juicyTargetsTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        l10n.foundCount(juicy.length),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (juicy.isEmpty)
                  Text(l10n.noJuicyTargets)
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: juicy.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final url = juicy[i];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.local_fire_department),
                        title: Text(
                          url,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                        trailing: IconButton(
                          tooltip: l10n.openScanFolder,
                          icon: const Icon(Icons.folder_open),
                          onPressed: () => openExternally(context, scanDir),
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder:
                                (_) => AlertDialog(
                                  title: Text(l10n.juicyTargetDialogTitle),
                                  content: SelectableText(url),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(l10n.close),
                                    ),
                                  ],
                                ),
                          );
                        },
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
