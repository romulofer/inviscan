import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

import '../utils/save_results.dart';

class ScanService {
  Future<(Set<String>, List<String>)> scanDomainWithProgress(
    String domain, {
    void Function(String log)? onLog,
    void Function()? onHttprobeStart,
    void Function(int current, int total)? onHttprobeProgress,
    void Function()? onHttprobeEnd,
  }) async {
    final Set<String> allSubdomains = {};
    final Set<String> active = {};
    final baseDomain = domain.trim();

    Future<int> runCommand(
      String name,
      List<String> args,
      Set<String> accumulator,
    ) async {
      final fullCommand = '$name ${args.join(' ')}';
      onLog?.call('[*] Executando $name com comando: $fullCommand');
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
      return accumulator.length;
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

    // crt.sh via HTML
    final crtshCommand =
        'curl -s "https://crt.sh/?q=%25.$baseDomain&exclude=expired"';
    onLog?.call('[*] Executando consulta ao crt.sh com comando: $crtshCommand');

    final crtsh = await Process.run('bash', ['-c', crtshCommand]);

    if (crtsh.exitCode == 0) {
      final Set<String> matches = {};

      final lines = crtsh.stdout.toString().split(RegExp(r'\r?\n'));
      final regex = RegExp(r'<TD>([^<]+)</TD>', caseSensitive: false);

      for (final line in lines) {
        final match = regex.firstMatch(line);
        if (match != null) {
          final value = match.group(1)!.trim();
          if (value.contains(baseDomain) &&
              !value.contains('*') &&
              !value.contains(' ')) {
            matches.add(value);
          }
        }
      }

      allSubdomains.addAll(matches);
      onLog?.call('[+] crt.sh encontrou ${matches.length} subdomínios.');
    } else {
      onLog?.call('[-] Erro ao consultar crt.sh');
    }

    // httprobe
    onLog?.call('[*] Iniciando verificação com httprobe...');
    onHttprobeStart?.call();

    final total = allSubdomains.length;
    var current = 0;

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
      current++;
      onHttprobeProgress?.call(current, total);
    }

    await httprobe.exitCode;
    onHttprobeEnd?.call();

    onLog?.call(
      '[+] httprobe identificou ${active.length} subdomínios ativos.',
    );
    onLog?.call(
      '[+] Total de subdomínios únicos encontrados: ${allSubdomains.length}',
    );

    // salva resultados e retorna diretório
    final scanDir = await saveResults(
      allSubdomains,
      allSubdomains.toSet(),
      active,
    );

    // gowitness
    if (active.isNotEmpty) {
      try {
        final gowitnessDir = Directory(p.join(scanDir.path, 'gowitness'));
        if (!await gowitnessDir.exists()) {
          await gowitnessDir.create(recursive: true);
        }

        final urlsFile = File(p.join(gowitnessDir.path, 'urls.txt'));
        await urlsFile.writeAsString(active.join('\n'));

        final gowitnessCommand =
            'gowitness scan file -f "${urlsFile.path}" --screenshot-path "${gowitnessDir.path}"';
        onLog?.call('[*] Executando gowitness com comando: $gowitnessCommand');

        final result = await Process.run('bash', ['-c', gowitnessCommand]);

        if (result.exitCode == 0) {
          onLog?.call('[+] gowitness finalizado com sucesso.');
        } else {
          onLog?.call('[-] gowitness encontrou erro:\n${result.stderr}');
        }
      } catch (e) {
        onLog?.call('[-] Erro ao executar gowitness: $e');
      }
    }

    return (allSubdomains, active.toList());
  }
}
