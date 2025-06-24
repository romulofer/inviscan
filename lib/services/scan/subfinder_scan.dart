import 'dart:convert';
import 'dart:io';

Future<int> runSubfinder({
  required String domain,
  required Set<String> accumulator,
  void Function(String log)? onLog,
}) async {
  final args = ['-d', domain];
  final fullCommand = 'subfinder ${args.join(' ')}';

  onLog?.call('[*] Executando subfinder com comando: $fullCommand');

  final process = await Process.start('subfinder', args, runInShell: true);
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
    onLog?.call('[-] subfinder terminou com erro (código $exitCode).');
  }

  final count = accumulator.length;
  onLog?.call('[+] subfinder encontrou $count subdomínios.');
  return count;
}
