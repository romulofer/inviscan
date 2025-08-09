import 'dart:convert';
import 'dart:io';
import '../../utils/binaries.dart';

Future<int> runAssetfinder({
  required String domain,
  required Set<String> accumulator,
  void Function(String log)? onLog,
}) async {
  final exec = binPath('assetfinder');
  final args = ['--subs-only', domain];
  onLog?.call('[*] Executando assetfinder: $exec ${args.join(' ')}');

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
      onLog?.call('[-] assetfinder terminou com erro (código $code).');
      if (stderrBuf.isNotEmpty) {
        onLog?.call(stderrBuf.toString().trim());
      }
    }
  } catch (e) {
    onLog?.call('[-] Falha ao executar assetfinder: $e');
  }

  final added = accumulator.length - initialLen;
  return added;
}
