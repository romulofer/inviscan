import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/command_utils.dart';

const _defaultAssetfinderCommand = 'assetfinder --subs-only DOMAIN';

Future<int> runAssetfinder({
  required String domain,
  required Set<String> accumulator,
  required AppLocalizations l10n,
  void Function(String log)? onLog,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final saved =
      prefs.getString('assetfinder_command') ?? _defaultAssetfinderCommand;
  final parts = tokenizeCommand(saved.replaceAll('DOMAIN', domain));
  if (parts.isEmpty) return 0;

  final exec = resolveExec(parts.first, 'assetfinder');
  final args = parts.skip(1).toList();
  onLog?.call(l10n.logAssetfinderRunning('$exec ${args.join(' ')}'));

  final initialLen = accumulator.length;

  try {
    final process = await Process.start(exec, args, runInShell: false);

    final stderrBuf = StringBuffer();

    // Drain stdout and stderr concurrently to avoid pipe-buffer deadlocks.
    final stdoutDone = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          final value = line.trim();
          if (value.isNotEmpty) accumulator.add(value);
        })
        .asFuture<void>();

    final stderrDone = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(stderrBuf.writeln)
        .asFuture<void>();

    final code = await process.exitCode;
    await Future.wait([stdoutDone, stderrDone]);

    if (code != 0) {
      onLog?.call(l10n.logAssetfinderError(code));
      final err = stderrBuf.toString().trim();
      if (err.isNotEmpty) onLog?.call(err);
    }
  } catch (e) {
    onLog?.call(l10n.logAssetfinderFailed(e));
  }

  final added = accumulator.length - initialLen;
  return added;
}
