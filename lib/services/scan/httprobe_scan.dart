import 'dart:async';
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
  onLog?.call('[*] Iniciando verificação com httprobe… ($total hosts)');
  onStart?.call();

  Process process;
  try {
    process = await Process.start(exec, const [], runInShell: false);
  } catch (e) {
    onLog?.call('[-] Falha ao iniciar httprobe: $e');
    onEnd?.call();
    return active;
  }

  final stderrBuf = StringBuffer();

  // Drain stdout and stderr concurrently to avoid pipe-buffer deadlocks.
  final stdoutDone = process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((line) {
        final url = line.trim();
        if (url.isNotEmpty) active.add(url);
      })
      .asFuture<void>();

  final stderrDone = process.stderr
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen(stderrBuf.writeln)
      .asFuture<void>();

  // Write all hosts to stdin, then close it.
  // Progress is reported as we feed hosts so the UI stays responsive.
  var current = 0;
  for (final host in subdomains) {
    process.stdin.writeln(host);
    current++;
    onProgress?.call(current, total);
  }
  await process.stdin.flush();
  await process.stdin.close();

  final code = await process.exitCode;
  await Future.wait([stdoutDone, stderrDone]);

  if (code == 0) {
    onLog?.call('[+] httprobe finalizado. Ativos: ${active.length}/$total.');
  } else {
    onLog?.call('[-] httprobe terminou com erro (code $code).');
    final err = stderrBuf.toString().trim();
    if (err.isNotEmpty) onLog?.call(err);
  }

  onEnd?.call();
  return active;
}
