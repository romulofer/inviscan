import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/binaries.dart';

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

  List<String> _tokenize(String cmd) {
    final List<String> out = [];
    final StringBuffer current = StringBuffer();
    bool inSingle = false, inDouble = false;

    for (int i = 0; i < cmd.length; i++) {
      final ch = cmd[i];
      if (ch == "'" && !inDouble) {
        inSingle = !inSingle;
        continue;
      }
      if (ch == '"' && !inSingle) {
        inDouble = !inDouble;
        continue;
      }
      if (ch == ' ' && !inSingle && !inDouble) {
        if (current.isNotEmpty) {
          out.add(current.toString());
          current.clear();
        }
      } else {
        current.write(ch);
      }
    }
    if (current.isNotEmpty) out.add(current.toString());
    return out;
  }

  final parts = _tokenize(resolvedCommand);
  if (parts.isEmpty) {
    onLog?.call('[-] Comando do FFUF vazio.');
    return foundSubdomains;
  }

  final exeToken = parts.first.toLowerCase();
  final ffufExec = exeToken.contains('ffuf') ? binPath('ffuf') : parts.first;

  final args = <String>[];
  args.addAll(parts.skip(1));

  String? outputPath;
  for (int i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '-o' && i + 1 < args.length) {
      outputPath = args[i + 1];
      break;
    }
  }

  onLog?.call('[*] Executando FFUF com o comando: $ffufExec ${args.join(' ')}');

  late ProcessResult proc;
  try {
    proc = await Process.run(ffufExec, args, runInShell: false);
  } catch (e) {
    onLog?.call('[-] Falha ao iniciar FFUF: $e');
    return foundSubdomains;
  }

  if (proc.exitCode != 0) {
    final err =
        (proc.stderr is String) ? proc.stderr as String : '${proc.stderr}';
    onLog?.call('[-] FFUF terminou com erro (code ${proc.exitCode}).');
    if (err.trim().isNotEmpty) onLog?.call(err.trim());
    return foundSubdomains;
  }

  final outFile = File(outputPath ?? '/tmp/ffuf_output.json');
  if (!await outFile.exists()) {
    onLog?.call(
      '[-] Arquivo de saída do FFUF não encontrado em: ${outFile.path}',
    );
    return foundSubdomains;
  }

  try {
    final data = jsonDecode(await outFile.readAsString());
    final results =
        (data is Map && data['results'] is List)
            ? (data['results'] as List)
            : const [];

    for (final r in results) {
      if (r is! Map) continue;
      final input = r['input'];
      String? url;
      if (input is Map && input['url'] is String) {
        url = input['url'] as String;
      } else if (r['url'] is String) {
        url = r['url'] as String;
      }
      if (url == null) continue;

      final host =
          url
              .replaceAll(RegExp(r'^https?://', caseSensitive: false), '')
              .split('/')
              .first;
      if (host.endsWith(domain)) {
        foundSubdomains.add(host);
      }
    }

    onLog?.call('[+] FFUF encontrou ${foundSubdomains.length} subdomínios.');
  } catch (e) {
    onLog?.call('[-] Erro ao processar JSON do FFUF: $e');
  }

  return foundSubdomains;
}
