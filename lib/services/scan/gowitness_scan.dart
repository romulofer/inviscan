import 'dart:io';
import 'package:path/path.dart' as p;
import '../../utils/binaries.dart';

Future<void> runGowitness({
  required List<String> activeSubdomains,
  required Directory scanDirectory,
  void Function(String log)? onLog,
}) async {
  if (activeSubdomains.isEmpty) {
    onLog?.call('[*] Nenhum subdomínio ativo para capturar com gowitness.');
    return;
  }

  final gowitnessDir = Directory(p.join(scanDirectory.path, 'gowitness'));
  await gowitnessDir.create(recursive: true);

  final targetsFile = File(p.join(scanDirectory.path, 'gowitness_targets.txt'));
  await targetsFile.writeAsString(activeSubdomains.join('\n'));
  onLog?.call('[*] URLs ativas salvas em ${targetsFile.path}');

  final dbPath = p.join(gowitnessDir.path, 'screenshots.db');
  final dbFile = File(dbPath);
  if (await dbFile.exists()) {
    await dbFile.delete();
    onLog?.call('[*] Banco de dados antigo removido: $dbPath');
  }

  final gowitnessExec = binPath('gowitness');

  final args = [
    'scan',
    'file',
    '-f',
    targetsFile.path,
    '--screenshot-path',
    gowitnessDir.path,
  ];

  onLog?.call('[*] Comando gowitness: $gowitnessExec ${args.join(' ')}');

  try {
    final result = await Process.run(
      gowitnessExec,
      args,
      runInShell: false,
      workingDirectory: scanDirectory.path,
    );

    if (result.exitCode == 0) {
      onLog?.call('[+] gowitness capturou screenshots com sucesso.');
      final out =
          (result.stdout is String)
              ? result.stdout as String
              : '${result.stdout}';
      if (out.trim().isNotEmpty) onLog?.call(out.trim());
    } else {
      final err =
          (result.stderr is String)
              ? result.stderr as String
              : '${result.stderr}';
      onLog?.call('[-] gowitness terminou com erro (code ${result.exitCode}).');
      if (err.trim().isNotEmpty) onLog?.call(err.trim());
    }
  } catch (e) {
    onLog?.call('[-] Falha ao executar gowitness: $e');
  }
}
