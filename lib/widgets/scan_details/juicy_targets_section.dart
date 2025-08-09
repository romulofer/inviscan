import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../utils/juicy_targets.dart';
import 'fs_helpers.dart';

class JuicyTargetsSection extends StatelessWidget {
  final Directory scanDir;
  const JuicyTargetsSection({Key? key, required this.scanDir})
    : super(key: key);

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
                    const Expanded(
                      child: Text(
                        'Juicy Targets',
                        style: TextStyle(
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
                        '${juicy.length} encontrados',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (juicy.isEmpty)
                  const Text('Nenhum alvo suculento identificado.')
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: juicy.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
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
                          tooltip: 'Abrir pasta do scan',
                          icon: const Icon(Icons.folder_open),
                          onPressed: () => openExternally(context, scanDir),
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder:
                                (_) => AlertDialog(
                                  title: const Text('Juicy Target'),
                                  content: SelectableText(url),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Fechar'),
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
