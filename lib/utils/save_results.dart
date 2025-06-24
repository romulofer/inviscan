import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

Future<Directory> saveResults(
  Set<String> total,
  Set<String> unique,
  Set<String> active, {
  void Function(String log)? onLog,
}) async {
  final homeDir =
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE']!;
  final baseDir = Directory(p.join(homeDir, 'inviscan_dart'));

  if (!await baseDir.exists()) {
    await baseDir.create(recursive: true);
    onLog?.call('[+] Criado diretório base: ${baseDir.path}');
  }

  final timestamp = DateFormat('ddMMyyyy_HHmmss').format(DateTime.now());
  final scanDir = Directory(p.join(baseDir.path, timestamp));
  await scanDir.create(recursive: true);
  onLog?.call('[+] Criado diretório do scan: ${scanDir.path}');

  final totalPath = p.join(scanDir.path, 'subdominios_totais.txt');
  await File(totalPath).writeAsString(total.join('\n'));
  onLog?.call('[+] Subdomínios totais salvos em: $totalPath');

  final uniquePath = p.join(scanDir.path, 'subdominios_unicos.txt');
  await File(uniquePath).writeAsString(unique.join('\n'));
  onLog?.call('[+] Subdomínios únicos salvos em: $uniquePath');

  final activePath = p.join(scanDir.path, 'subdominios_unicos_ativos.txt');
  await File(activePath).writeAsString(active.join('\n'));
  onLog?.call('[+] Subdomínios ativos salvos em: $activePath');

  return scanDir;
}
