import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/command_utils.dart';

/// Placeholders `TARGETS` (arquivo de alvos) e `SCREENSHOTS` (diretório de
/// saída) são injetados em runtime — o app controla esses caminhos.
const _defaultGowitnessCommand =
    'gowitness scan file -f TARGETS --screenshot-path SCREENSHOTS --write-none';

Future<void> runGowitness({
  required List<String> activeSubdomains,
  required Directory scanDirectory,
  required AppLocalizations l10n,
  void Function(String log)? onLog,
}) async {
  if (activeSubdomains.isEmpty) {
    onLog?.call(l10n.logGowitnessNone);
    return;
  }

  final gowitnessDir = Directory(p.join(scanDirectory.path, 'gowitness'));
  await gowitnessDir.create(recursive: true);

  final targetsFile = File(p.join(scanDirectory.path, 'gowitness_targets.txt'));
  await targetsFile.writeAsString(activeSubdomains.join('\n'));
  onLog?.call(l10n.logGowitnessTargetsSaved(targetsFile.path));

  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString('gowitness_command') ?? _defaultGowitnessCommand;
  final parts = tokenizeCommand(
    saved
        .replaceAll('TARGETS', targetsFile.path)
        .replaceAll('SCREENSHOTS', gowitnessDir.path),
  );
  if (parts.isEmpty) {
    onLog?.call(l10n.logGowitnessFailed('empty command'));
    return;
  }

  final gowitnessExec = resolveExec(parts.first, 'gowitness');
  final args = parts.skip(1).toList();

  onLog?.call(l10n.logGowitnessRunning('$gowitnessExec ${args.join(' ')}'));

  try {
    final process = await Process.start(
      gowitnessExec,
      args,
      runInShell: false,
      workingDirectory: scanDirectory.path,
    );

    final outBuf = StringBuffer();
    final errBuf = StringBuffer();

    // Drain both streams concurrently to avoid pipe-buffer deadlocks.
    final stdoutDone = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(outBuf.writeln)
        .asFuture<void>();

    final stderrDone = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(errBuf.writeln)
        .asFuture<void>();

    final code = await process.exitCode;
    await Future.wait([stdoutDone, stderrDone]);

    if (code == 0) {
      onLog?.call(l10n.logGowitnessSuccess);
      final out = outBuf.toString().trim();
      if (out.isNotEmpty) onLog?.call(out);
    } else {
      onLog?.call(l10n.logGowitnessError(code));
      final err = errBuf.toString().trim();
      if (err.isNotEmpty) onLog?.call(err);
    }
  } catch (e) {
    onLog?.call(l10n.logGowitnessFailed(e));
  }
}
