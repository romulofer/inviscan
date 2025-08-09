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

  try {
    final client = HttpClient()..userAgent = 'Mozilla/5.0 (Flutter; Inviscan)';
    final req = await client.getUrl(url);
    final res = await req.close();

    if (res.statusCode != 200) {
      onLog?.call('[-] crt.sh respondeu com status ${res.statusCode}.');
      return 0;
    }

    final html = await res.transform(utf8.decoder).join();

    final tdRegex = RegExp(r'<TD>([^<]+)</TD>', caseSensitive: false);
    final Set<String> matches = {};

    for (final m in tdRegex.allMatches(html)) {
      final value = m.group(1)!.trim();
      if (value.contains(domain) &&
          !value.contains('*') &&
          !value.contains(' ')) {
        matches.add(value);
      }
    }

    accumulator.addAll(matches);
  } catch (e) {
    onLog?.call('[-] Erro ao consultar/parsing crt.sh: $e');
  }

  final added = accumulator.length - initialLen;
  return added;
}
