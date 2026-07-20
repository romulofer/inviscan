import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/binaries.dart';
import '../../utils/browser.dart';

/// SharedPreferences key holding the user-configured Chrome/Edge binary path.
const gowitnessChromePathKey = 'gowitness_chrome_path';

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

  // gowitness drives a headless Chrome over CDP. Resolve a local browser
  // (configured path → Chrome → Edge). If none is found, skip the step with a
  // clear log instead of failing deep inside gowitness.
  final prefs = await SharedPreferences.getInstance();
  final configuredChrome = prefs.getString(gowitnessChromePathKey);
  final browserPath = resolveBrowserPath(configuredChrome);
  if (browserPath == null) {
    onLog?.call(l10n.logGowitnessNoBrowser);
    return;
  }
  onLog?.call(l10n.logGowitnessBrowser(browserPath));

  final gowitnessDir = Directory(p.join(scanDirectory.path, 'gowitness'));
  await gowitnessDir.create(recursive: true);

  final targetsFile = File(p.join(scanDirectory.path, 'gowitness_targets.txt'));
  await targetsFile.writeAsString(activeSubdomains.join('\n'));
  onLog?.call(l10n.logGowitnessTargetsSaved(targetsFile.path));

  final gowitnessExec = binPath('gowitness');

  final args = [
    'scan',
    'file',
    '-f',
    targetsFile.path,
    '--screenshot-path',
    gowitnessDir.path,
    '--chrome-path',
    browserPath,
    '--write-none',
  ];

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
