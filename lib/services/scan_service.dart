import 'dart:io';

class ScanService {
  Future<(Set<String>, List<String>)> scanDomain(String domain) async {
    final Set<String> results = {};
    final List<String> logs = [];

    logs.add('[*] Rodando subfinder com comando: subfinder -d $domain');
    final subfinder = await Process.run('subfinder', ['-d', domain]);
    if (subfinder.exitCode == 0) {
      final found =
          (subfinder.stdout as String)
              .split('\n')
              .where((e) => e.trim().isNotEmpty)
              .toSet();
      results.addAll(found);
      logs.add('[+] subfinder encontrou ${found.length} resultados.');
    } else {
      logs.add('[!] subfinder retornou erro: ${subfinder.stderr}');
    }

    logs.add(
      '[*] Rodando assetfinder com comando: assetfinder --subs-only $domain',
    );
    final assetfinder = await Process.run('assetfinder', [
      '--subs-only',
      domain,
    ]);
    if (assetfinder.exitCode == 0) {
      final found =
          (assetfinder.stdout as String)
              .split('\n')
              .where((e) => e.trim().isNotEmpty)
              .toSet();
      results.addAll(found);
      logs.add('[+] assetfinder encontrou ${found.length} resultados.');
    } else {
      logs.add('[!] assetfinder retornou erro: ${assetfinder.stderr}');
    }

    logs.add(
      '[*] Consultando crt.sh (HTML) com certificados válidos apenas...',
    );
    final crtsh = await Process.run('bash', [
      '-c',
      'curl -s "https://crt.sh/?q=%25.$domain&exclude=expired"',
    ]);

    if (crtsh.exitCode == 0) {
      final Set<String> found = {};

      final matches = RegExp(
        r'<TD>([^<]*\.' +
            RegExp.escape(domain) +
            r'(?:<BR>[^<]*\.' +
            RegExp.escape(domain) +
            r')*)<\/TD>',
        caseSensitive: false,
      ).allMatches(crtsh.stdout);

      for (final match in matches) {
        final raw = match.group(1)!;
        final parts = raw
            .split('<BR>')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty);
        found.addAll(parts);
      }

      results.addAll(found);
      logs.add('[+] crt.sh (HTML) encontrou ${found.length} resultados.');
    } else {
      logs.add('[!] crt.sh retornou erro: ${crtsh.stderr}');
    }

    logs.add('[*] Total de subdomínios únicos encontrados: ${results.length}');
    return (results, logs);
  }
}
