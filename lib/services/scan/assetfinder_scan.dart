import 'dart:convert';
import 'dart:io';

Future<int> runAssetfinder({
  required String domain,
  required Set<String> accumulator,
  void Function(String log)? onLog,
}) async {
  final args = ['--subs-only', domain];
  final fullCommand = 'assetfinder ${args.join(' ')}';

  onLog?.call('[*] Executando assetfinder com comando: $fullCommand');

  final process = await Process.start('assetfinder', args, runInShell: true);
  await for (var line in process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())) {
    final value = line.trim();
    if (value.isNotEmpty) {
      accumulator.add(value);
    }
  }

  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    onLog?.call('[-] assetfinder terminou com erro (código $exitCode).');
  }

  final count = accumulator.length;
  return count;
}
