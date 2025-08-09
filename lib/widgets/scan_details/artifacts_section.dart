import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import 'fs_helpers.dart';

class ArtifactsSection extends StatelessWidget {
  final Directory scanDir;
  const ArtifactsSection({Key? key, required this.scanDir}) : super(key: key);

  Future<List<FileSystemEntity>> _listTopArtifacts() async {
    if (!await scanDir.exists()) return [];
    final all =
        await scanDir.list(recursive: false, followLinks: false).toList();
    all.sort((a, b) {
      final da = a is Directory ? 0 : 1;
      final db = b is Directory ? 0 : 1;
      final byType = da.compareTo(db);
      return byType != 0
          ? byType
          : a.path.toLowerCase().compareTo(b.path.toLowerCase());
    });
    return all;
  }

  Future<String> _readSmallText(File f, {int maxBytes = 200 * 1024}) async {
    final len = await f.length();
    if (len > maxBytes)
      return 'Arquivo grande (${len} bytes). Abra externamente.';
    return f.readAsString();
  }

  bool _isText(FileSystemEntity e) =>
      e is File &&
      (e.path.toLowerCase().endsWith('.txt') ||
          e.path.toLowerCase().endsWith('.log') ||
          e.path.toLowerCase().endsWith('.json'));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FileSystemEntity>>(
      future: _listTopArtifacts(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final items = snap.data ?? [];
        final texts = items.where(_isText).toList();
        final others = items.where((e) => !_isText(e)).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (texts.isNotEmpty) ...[
              const Text(
                'Arquivos de texto/JSON',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...texts.map((e) {
                final f = e as File;
                final name = p.basename(f.path);
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.description),
                    title: Text(name),
                    subtitle: Text(f.path),
                    trailing: IconButton(
                      tooltip: 'Abrir pasta',
                      icon: const Icon(Icons.folder_open),
                      onPressed: () => openExternally(context, f),
                    ),
                    onTap: () async {
                      final content = await _readSmallText(f);
                      // ignore: use_build_context_synchronously
                      showDialog(
                        context: context,
                        builder:
                            (_) => AlertDialog(
                              title: Text(name),
                              content: SingleChildScrollView(
                                child: SelectableText(content),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Fechar'),
                                ),
                              ],
                            ),
                      );
                    },
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],
            if (others.isNotEmpty) ...[
              const Text(
                'Outros artefatos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...others.map((e) {
                final name = p.basename(e.path);
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.insert_drive_file),
                    title: Text(name),
                    subtitle: Text(e.path),
                    trailing: IconButton(
                      tooltip: 'Abrir pasta',
                      icon: const Icon(Icons.folder_open),
                      onPressed: () => openExternally(context, e),
                    ),
                  ),
                );
              }),
            ],
          ],
        );
      },
    );
  }
}
