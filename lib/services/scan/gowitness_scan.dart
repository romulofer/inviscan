import 'dart:async';
import 'dart:convert';
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
  onLog?.call('[+] URLs ativas salvas em ${targetsFile.path}');

  final gowitnessExec = binPath('gowitness');

  final args = [
    'scan',
    'file',
    '-f',
    targetsFile.path,
    '--screenshot-path',
    gowitnessDir.path,
  ];

  onLog?.call(
    '[*] Executando gowitness: $gowitnessExec ${args.join(' ')}',
  );

  try {
    final process = await Process.start(
      gowitnessExec,
      args,
      runInShell: false,
      workingDirectory: scanDirectory.path,
    );

    final outBuf = StringBuffer();
    final errBuf = StringBuffer();

    // Drain both streams concurrently to avoid pipe-buffer deadlocks.
    final stdoutDone = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(outBuf.writeln)
        .asFuture<void>();

    final stderrDone = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(errBuf.writeln)
        .asFuture<void>();

    final code = await process.exitCode;
    await Future.wait([stdoutDone, stderrDone]);

    if (code == 0) {
      onLog?.call('[+] gowitness capturou screenshots com sucesso.');
      final out = outBuf.toString().trim();
      if (out.isNotEmpty) onLog?.call(out);
    } else {
      onLog?.call('[-] gowitness terminou com erro (code $code).');
      final err = errBuf.toString().trim();
      if (err.isNotEmpty) onLog?.call(err);
    }
  } catch (e) {
    onLog?.call('[-] Falha ao executar gowitness: $e');
  }
}
