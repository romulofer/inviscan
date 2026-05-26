import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../../utils/binaries.dart';

Future<int> runSubfinder({
  required String domain,
  required Set<String> accumulator,
  void Function(String log)? onLog,
}) async {
  final exec = binPath('subfinder');
  final args = ['-d', domain, '-silent', '-all'];
  onLog?.call('[*] Executando subfinder: $exec ${args.join(' ')}');

  final initialLen = accumulator.length;

  try {
    final process = await Process.start(exec, args, runInShell: false);

    final stderrBuf = StringBuffer();

    // Drain stdout and stderr concurrently to avoid pipe-buffer deadlocks.
    final stdoutDone = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          final value = line.trim();
          if (value.isNotEmpty) accumulator.add(value);
        })
        .asFuture<void>();

    final stderrDone = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(stderrBuf.writeln)
        .asFuture<void>();

    final code = await process.exitCode;
    await Future.wait([stdoutDone, stderrDone]);

    if (code != 0) {
      onLog?.call('[-] subfinder terminou com erro (código $code).');
      final err = stderrBuf.toString().trim();
      if (err.isNotEmpty) onLog?.call(err);
    }
  } catch (e) {
    onLog?.call('[-] Falha ao executar subfinder: $e');
  }

  final added = accumulator.length - initialLen;
  return added;
}
