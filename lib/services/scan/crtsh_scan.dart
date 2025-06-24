import 'dart:io';

Future<int> runCrtsh({
  required String domain,
  required Set<String> accumulator,
  void Function(String log)? onLog,
}) async {
  final command = 'curl -s "https://crt.sh/?q=%25.$domain&exclude=expired"';
  onLog?.call('[*] Executando consulta ao crt.sh com comando: $command');

  final result = await Process.run('bash', ['-c', command]);

  if (result.exitCode != 0) {
    onLog?.call('[-] Erro ao consultar crt.sh');
    return 0;
  }

  final Set<String> matches = {};
  final lines = result.stdout.toString().split(RegExp(r'\r?\n'));
  final regex = RegExp(r'<TD>([^<]+)</TD>', caseSensitive: false);

  for (final line in lines) {
    final match = regex.firstMatch(line);
    if (match != null) {
      final value = match.group(1)!.trim();
      if (value.contains(domain) &&
          !value.contains('*') &&
          !value.contains(' ')) {
        matches.add(value);
      }
    }
  }

  accumulator.addAll(matches);
  onLog?.call('[+] crt.sh encontrou ${matches.length} subdomínios.');
  return matches.length;
}
