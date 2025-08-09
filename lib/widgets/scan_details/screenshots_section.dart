import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import 'fs_helpers.dart';

class ScreenshotsSection extends StatelessWidget {
  final Directory scanDir;
  const ScreenshotsSection({Key? key, required this.scanDir}) : super(key: key);

  Future<List<File>> _listScreenshots() async {
    final shotsDir = Directory(p.join(scanDir.path, 'gowitness')); // sua pasta
    if (!await shotsDir.exists()) return [];
    final files =
        await shotsDir
            .list(recursive: true, followLinks: false)
            .where((e) => e is File)
            .cast<File>()
            .toList();
    files.retainWhere((f) {
      final name = f.path.toLowerCase();
      return name.endsWith('.png') ||
          name.endsWith('.jpg') ||
          name.endsWith('.jpeg') ||
          name.endsWith('.webp');
    });
    files.sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));
    return files;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<File>>(
      future: _listScreenshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: LinearProgressIndicator(),
          );
        }
        final shots = snap.data ?? [];
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
                        'Screenshots (Gowitness)',
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
                        '${shots.length}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (shots.isEmpty)
                  const Text('Nenhuma captura encontrada em /gowitness.')
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 6,
                          crossAxisSpacing: 6,
                        ),
                    itemCount: shots.length,
                    itemBuilder: (_, i) {
                      final f = shots[i];
                      return InkWell(
                        onTap:
                            () => showDialog(
                              context: context,
                              builder:
                                  (_) => Dialog(
                                    child: InteractiveViewer(
                                      child: Image.file(f, fit: BoxFit.contain),
                                    ),
                                  ),
                            ),
                        child: Image.file(f, fit: BoxFit.cover),
                      );
                    },
                  ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => openExternally(context, scanDir),
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Abrir pasta de screenshots'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
