import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../l10n/app_localizations.dart';

class LogUtils {
  static Color getLogColor(String log) {
    if (log.startsWith('[+]')) return Colors.green.shade700;
    if (log.startsWith('[*]')) return Colors.blue.shade700;
    if (log.startsWith('[!]')) return Colors.orange.shade800;
    if (log.startsWith('[-]')) return Colors.red.shade700;
    return Colors.black;
  }

  static Future<void> copyLogs(BuildContext context, List<String> logs) async {
    final text = logs.join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).logsCopied)),
      );
    }
  }

  static Future<void> saveLogs(
    BuildContext context,
    List<String> logs, {
    String? domain,
  }) async {
    if (logs.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).noLogsToSave)),
        );
      }
      return;
    }
    try {
      final dir = await getApplicationDocumentsDirectory();
      final logsDir = Directory('${dir.path}/logs');
      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }
      final ts = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-');
      final safeDomain = (domain ?? 'scan').replaceAll(
        RegExp(r'[^a-zA-Z0-9._-]'),
        '_',
      );
      final file = File('${logsDir.path}/scan_logs_${safeDomain}_$ts.txt');
      await file.writeAsString(logs.join('\n'));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).logsSavedAt(file.path)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).saveLogsFailed(e)),
          ),
        );
      }
    }
  }
}
