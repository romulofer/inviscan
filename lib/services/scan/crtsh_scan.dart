import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<int> runCrtsh({
  required String domain,
  required Set<String> accumulator,
  void Function(String log)? onLog,
}) async {
  final url = Uri.parse('https://crt.sh/?q=%25.$domain&exclude=expired');
  onLog?.call('[*] Consultando crt.sh: $url');

  final initialLen = accumulator.length;
  final client = HttpClient()
    ..userAgent = 'Mozilla/5.0 (Flutter; Inviscan)'
    ..connectionTimeout = const Duration(seconds: 30);

  try {
    final req = await client
        .getUrl(url)
        .timeout(const Duration(seconds: 30));
    final res = await req.close().timeout(const Duration(seconds: 60));

    if (res.statusCode != 200) {
      onLog?.call('[-] crt.sh respondeu com status ${res.statusCode}.');
      return 0;
    }

    final html = await res
        .transform(utf8.decoder)
        .join()
        .timeout(const Duration(seconds: 60));

    final tdRegex = RegExp(r'<TD>([^<]+)</TD>', caseSensitive: false);

    for (final m in tdRegex.allMatches(html)) {
      final value = m.group(1)!.trim();
      if (value.contains(domain) &&
          !value.contains('*') &&
          !value.contains(' ')) {
        accumulator.add(value);
      }
    }
  } on TimeoutException {
    onLog?.call('[-] crt.sh: timeout ao conectar ou receber dados.');
  } catch (e) {
    onLog?.call('[-] Erro ao consultar/parsing crt.sh: $e');
  } finally {
    client.close(force: true);
  }

  final added = accumulator.length - initialLen;
  onLog?.call('[+] crt.sh adicionou $added subdomínios.');
  return added;
}
