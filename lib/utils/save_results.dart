import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

Future<Directory> saveResults(
  Set<String> total,
  Set<String> unique,
  Set<String> active,
) async {
  final homeDir =
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE']!;
  final baseDir = Directory(p.join(homeDir, 'inviscan_dart'));

  if (!await baseDir.exists()) {
    await baseDir.create(recursive: true);
  }

  final timestamp = DateFormat('ddMMyyyy_HHmmss').format(DateTime.now());
  final scanDir = Directory(p.join(baseDir.path, timestamp));
  await scanDir.create(recursive: true);

  await File(
    p.join(scanDir.path, 'subdominios_totais.txt'),
  ).writeAsString(total.join('\n'));

  await File(
    p.join(scanDir.path, 'subdominios_unicos.txt'),
  ).writeAsString(unique.join('\n'));

  await File(
    p.join(scanDir.path, 'subdominios_unicos_ativos.txt'),
  ).writeAsString(active.join('\n'));

  return scanDir;
}
