import 'dart:io';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

Future<void> openExternally(BuildContext context, FileSystemEntity e) async {
  final path = e.path;
  final dirToOpen = e is Directory ? path : File(path).parent.path;
  try {
    if (Platform.isLinux) {
      await Process.run('xdg-open', [dirToOpen]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [dirToOpen]);
    } else if (Platform.isWindows) {
      // explorer.exe requires backslashes and does not accept forward slashes
      // reliably when the path contains spaces.
      await Process.run(
        'explorer',
        [dirToOpen.replaceAll('/', '\\')],
        runInShell: false,
      );
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).openManually)),
        );
      }
    }
  } catch (err) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).couldNotOpen(err)),
        ),
      );
    }
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
