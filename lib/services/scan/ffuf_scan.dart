import 'dart:convert';
import 'dart:io';

Future<Set<String>> runFfufSubdomainScan(
  String domain, {
  void Function(String log)? onLog,
}) async {
  final Set<String> foundSubdomains = {};
  final wordlistPath = 'lib/wordlists/ffuf/wordlist.txt';

  onLog?.call('[*] Executando FFUF para descoberta de subdomínios...');
  final ffufCommand = [
    'ffuf',
    '-w',
    wordlistPath,
    '-u',
    'http://FUZZ.$domain',
    '-mc',
    '200',
    '-of',
    'json',
    '-o',
    '/tmp/ffuf_output.json',
  ];

  onLog?.call('[*] Comando: ${ffufCommand.join(' ')}');

  final process = await Process.run(
    ffufCommand.first,
    ffufCommand.sublist(1),
    runInShell: true,
  );

  if (process.exitCode != 0) {
    onLog?.call('[-] FFUF encontrou um erro: ${process.stderr}');
    return foundSubdomains;
  }

  final outputFile = File('/tmp/ffuf_output.json');
  if (!await outputFile.exists()) {
    onLog?.call('[-] Arquivo de saída do FFUF não encontrado.');
    return foundSubdomains;
  }

  try {
    final jsonData = jsonDecode(await outputFile.readAsString());
    final results = jsonData['results'] as List<dynamic>;

    for (final result in results) {
      final url = result['input']['url'] as String;
      final sub = url.replaceAll(RegExp(r'https?://'), '').split('/').first;
      if (sub.endsWith(domain)) {
        foundSubdomains.add(sub);
      }
    }

    onLog?.call('[+] FFUF encontrou ${foundSubdomains.length} subdomínios.');
  } catch (e) {
    onLog?.call('[-] Erro ao processar resultado do FFUF: $e');
  }

  return foundSubdomains;
}
