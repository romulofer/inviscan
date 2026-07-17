import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../../l10n/app_localizations.dart';

Future<int> runCrtsh({
  required String domain,
  required Set<String> accumulator,
  required AppLocalizations l10n,
  void Function(String log)? onLog,
}) async {
  // Endpoint JSON é mais estável que raspar o HTML da tabela.
  final url = Uri.parse('https://crt.sh/?q=%25.$domain&exclude=expired&output=json');
  onLog?.call(l10n.logCrtshQuerying('$url'));

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
      onLog?.call(l10n.logCrtshStatus(res.statusCode));
      return 0;
    }

    final body = await res
        .transform(utf8.decoder)
        .join()
        .timeout(const Duration(seconds: 60));

    final decoded = jsonDecode(body);
    if (decoded is! List) {
      onLog?.call(l10n.logCrtshBadJson);
      return 0;
    }

    final suffix = '.$domain';
    for (final entry in decoded) {
      if (entry is! Map) continue;
      final nameValue = entry['name_value'];
      if (nameValue is! String) continue;

      // Um único registro pode listar vários nomes separados por newline.
      for (var name in nameValue.split('\n')) {
        name = name.trim().toLowerCase();
        if (name.startsWith('*.')) name = name.substring(2);
        if (name.isEmpty || name.contains(' ') || name.contains('*')) continue;
        // Casa apenas o domínio alvo ou seus subdomínios, não sufixos maliciosos
        // como "example.com.attacker.net".
        if (name == domain || name.endsWith(suffix)) {
          accumulator.add(name);
        }
      }
    }
  } on TimeoutException {
    onLog?.call(l10n.logCrtshTimeout);
  } catch (e) {
    onLog?.call(l10n.logCrtshError(e));
  } finally {
    client.close(force: true);
  }

  final added = accumulator.length - initialLen;
  onLog?.call(l10n.logCrtshAdded(added));
  return added;
}
