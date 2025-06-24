import 'dart:io';
import 'package:path/path.dart' as p;

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
  if (!await gowitnessDir.exists()) {
    await gowitnessDir.create(recursive: true);
  }

  final targetsFile = File(p.join(scanDirectory.path, 'gowitness_targets.txt'));
  await targetsFile.writeAsString(activeSubdomains.join('\n'));
  onLog?.call('[*] Subdomínios ativos salvos em ${targetsFile.path}');

  final gowitnessDb = File('gowitness.sqlite3');
  if (await gowitnessDb.exists()) {
    await gowitnessDb.delete();
    onLog?.call('[*] Banco de dados gowitness.sqlite3 removido.');
  }

  final initResult = await Process.run('gowitness', ['init'], runInShell: true);
  if (initResult.exitCode != 0) {
    onLog?.call('[-] Erro ao inicializar gowitness: ${initResult.stderr}');
    return;
  }
  onLog?.call('[+] gowitness iniciado com sucesso.');

  final command = [
    'gowitness',
    'file',
    '--source',
    targetsFile.path,
    '--destination',
    gowitnessDir.path,
  ];
  onLog?.call('[*] Executando gowitness com comando: ${command.join(' ')}');

  final result = await Process.run(
    command.first,
    command.sublist(1),
    runInShell: true,
  );
  if (result.exitCode == 0) {
    onLog?.call('[+] gowitness capturou screenshots com sucesso.');
  } else {
    onLog?.call('[-] gowitness encontrou erro: ${result.stderr}');
  }
}
