import 'dart:convert';
import 'dart:io';

Future<Set<String>> runHttprobe({
  required Set<String> subdomains,
  void Function(String log)? onLog,
  void Function()? onStart,
  void Function(int current, int total)? onProgress,
  void Function()? onEnd,
}) async {
  final Set<String> active = {};
  final total = subdomains.length;
  var current = 0;

  onLog?.call('[*] Iniciando verificação com httprobe...');
  onStart?.call();

  final process = await Process.start('httprobe', [], runInShell: true);

  for (final sub in subdomains) {
    process.stdin.writeln(sub);
  }
  await process.stdin.close();

  await for (var line in process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())) {
    final url = line.trim();
    if (url.isNotEmpty) {
      active.add(url);
    }
    current++;
    onProgress?.call(current, total);
  }

  await process.exitCode;
  onEnd?.call();

  onLog?.call('[+] httprobe identificou ${active.length} subdomínios ativos.');

  return active;
}
