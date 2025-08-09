import 'dart:convert';
import 'dart:io';
import '../../utils/binaries.dart';

Future<Set<String>> runHttprobe({
  required Set<String> subdomains,
  void Function(String log)? onLog,
  void Function()? onStart,
  void Function(int current, int total)? onProgress,
  void Function()? onEnd,
}) async {
  final Set<String> active = {};
  final total = subdomains.length;

  if (total == 0) {
    onLog?.call('[*] Nenhum subdomínio para verificar com httprobe.');
    onStart?.call();
    onProgress?.call(0, 0);
    onEnd?.call();
    return active;
  }

  final exec = binPath('httprobe');
  onLog?.call('[*] Iniciando verificação com httprobe… (${total} hosts)');
  onStart?.call();

  Process process;
  try {
    process = await Process.start(exec, const [], runInShell: false);
  } catch (e) {
    onLog?.call('[-] Falha ao iniciar httprobe: $e');
    onEnd?.call();
    return active;
  }

  final stdoutSub = process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((line) {
        final url = line.trim();
        if (url.isNotEmpty) {
          active.add(url);
        }
      });

  final StringBuffer stderrBuf = StringBuffer();
  final stderrSub = process.stderr
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen(stderrBuf.writeln);

  var current = 0;
  for (final host in subdomains) {
    process.stdin.writeln(host);
    current++;
    onProgress?.call(current, total);
  }
  await process.stdin.flush();
  await process.stdin.close();

  final code = await process.exitCode;
  await stdoutSub.cancel();
  await stderrSub.cancel();

  if (code == 0) {
    onLog?.call('[+] httprobe finalizado. Ativos: ${active.length}/${total}.');
  } else {
    onLog?.call('[-] httprobe terminou com erro (code $code).');
    final err = stderrBuf.toString().trim();
    if (err.isNotEmpty) onLog?.call(err);
  }

  onEnd?.call();
  return active;
}
