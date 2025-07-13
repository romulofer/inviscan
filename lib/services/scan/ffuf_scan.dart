import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

Future<Set<String>> runFfufSubdomainScan(
  String domain, {
  void Function(String log)? onLog,
}) async {
  final Set<String> foundSubdomains = {};

  const defaultCommand =
      'ffuf -w lib/wordlists/ffuf/wordlist.txt -u http://FUZZ.DOMAIN -mc 200 -of json -o /tmp/ffuf_output.json';

  final prefs = await SharedPreferences.getInstance();
  final savedCommand = prefs.getString('ffuf_command') ?? defaultCommand;

  final resolvedCommand = savedCommand.replaceAll('DOMAIN', domain);

  onLog?.call('[*] Executando FFUF para descoberta de subdomínios...');
  onLog?.call('[*] Comando: $resolvedCommand');

  final parts = resolvedCommand.split(' ').where((p) => p.isNotEmpty).toList();

  final process = await Process.run(
    parts.first,
    parts.sublist(1),
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
      final input = result['input'] as Map<String, dynamic>?;
      final url = input?['url'] as String?;

      if (url == null) continue; // Pula se não tiver URL

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
