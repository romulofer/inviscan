import 'dart:io';
import 'package:flutter/material.dart';

Future<void> openExternally(BuildContext context, FileSystemEntity e) async {
  final path = e.path;
  final dirToOpen = e is Directory ? path : File(path).parent.path;
  try {
    if (Platform.isLinux) {
      await Process.run('xdg-open', [dirToOpen]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [dirToOpen]);
    } else if (Platform.isWindows) {
      await Process.run('explorer', [dirToOpen]);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Abra manualmente pelo gerenciador de arquivos.'),
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Não foi possível abrir: $e')));
  }
}

bool isTextFile(String path) {
  final name = path.toLowerCase();
  return name.endsWith('.txt') ||
      name.endsWith('.log') ||
      name.endsWith('.json');
}

bool isImageFile(String path) {
  final name = path.toLowerCase();
  return name.endsWith('.png') ||
      name.endsWith('.jpg') ||
      name.endsWith('.jpeg') ||
      name.endsWith('.webp');
}
