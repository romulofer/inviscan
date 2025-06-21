import 'dart:convert';
import 'dart:io';
import 'package:inviscan/utils/save_results.dart';

class ScanService {
  Future<(Set<String>, List<String>, List<String>)> scanDomain(
    String domain, {
    void Function(String log)? onLog,
  }) async {
    final Set<String> allSubdomains = {};
    final Set<String> active = {};

    final baseDomain = domain.trim();

    Future<int> runCommand(
      String name,
      List<String> args,
      Set<String> accumulator,
    ) async {
      onLog?.call('[*] Executando $name com comando: $name ${args.join(' ')}');

      final before = accumulator.length;
      final process = await Process.start(name, args, runInShell: true);

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
        onLog?.call('[-] $name terminou com erro (código $exitCode).');
      }

      return accumulator.length - before;
    }

    // subfinder
    final subfinderCount = await runCommand('subfinder', [
      '-d',
      baseDomain,
    ], allSubdomains);
    onLog?.call('[+] subfinder encontrou $subfinderCount subdomínios.');

    // assetfinder
    final assetfinderCount = await runCommand('assetfinder', [
      '--subs-only',
      baseDomain,
    ], allSubdomains);
    onLog?.call('[+] assetfinder encontrou $assetfinderCount subdomínios.');

    // crt.sh
    onLog?.call('[*] Consultando crt.sh...');
    final crtsh = await Process.run('bash', [
      '-c',
      'curl -s "https://crt.sh/?q=%25.$baseDomain&exclude=expired"',
    ]);

    if (crtsh.exitCode == 0) {
      final matches =
          RegExp(r'<TD>([\w\.\-\*]+)<(?:BR>|\/TD>)')
              .allMatches(crtsh.stdout)
              .map((m) => m.group(1)!)
              .where((e) => e.contains(baseDomain))
              .toSet();

      allSubdomains.addAll(matches);
      onLog?.call('[+] crt.sh encontrou ${matches.length} subdomínios.');
    } else {
      onLog?.call('[-] Erro ao consultar crt.sh');
    }

    // httprobe
    onLog?.call('[*] Iniciando verificação com httprobe...');
    final httprobe = await Process.start('httprobe', [], runInShell: true);
    for (final sub in allSubdomains) {
      httprobe.stdin.writeln(sub);
    }
    await httprobe.stdin.close();

    await for (var line in httprobe.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())) {
      final url = line.trim();
      if (url.isNotEmpty) {
        active.add(url);
      }
    }

    await httprobe.exitCode;
    onLog?.call(
      '[+] httprobe identificou ${active.length} subdomínios ativos.',
    );
    onLog?.call(
      '[+] Total de subdomínios únicos encontrados: ${allSubdomains.length}',
    );

    await saveResults(allSubdomains, allSubdomains.toSet(), active);
    return (allSubdomains, <String>[], active.toList());
  }
}
