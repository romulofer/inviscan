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
  final stderrBuf = StringBuffer();

  try {
    final process = await Process.start(exec, args, runInShell: false);

    final stdoutLines = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    await for (final line in stdoutLines) {
      final value = line.trim();
      if (value.isNotEmpty) {
        accumulator.add(value);
      }
    }

    final stderrLines = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    await for (final line in stderrLines) {
      stderrBuf.writeln(line);
    }

    final code = await process.exitCode;
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
