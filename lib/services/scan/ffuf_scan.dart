import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/command_utils.dart';

Future<Set<String>> runFfufSubdomainScan(
  String domain, {
  required AppLocalizations l10n,
  void Function(String log)? onLog,
}) async {
  final Set<String> foundSubdomains = {};

  // Use a cross-platform temp directory instead of the hardcoded /tmp path.
  final tempDir = await getTemporaryDirectory();
  final defaultOutputPath = p.join(tempDir.path, 'ffuf_output.json');

  // Prefer wordlist bundled next to the executable (packaged builds),
  // then fall back to the project's lib/ directory (development runs).
  final wlInExec = File(p.join(
    File(Platform.resolvedExecutable).parent.path,
    'wordlists', 'ffuf', 'wordlist.txt',
  ));
  final wlInCwd = File(p.join(
    Directory.current.path,
    'lib', 'wordlists', 'ffuf', 'wordlist.txt',
  ));
  final defaultWordlist = wlInExec.existsSync()
      ? wlInExec.path
      : (wlInCwd.existsSync() ? wlInCwd.path : wlInExec.path);

  final defaultCommand =
      'ffuf -w "$defaultWordlist" -u http://FUZZ.DOMAIN -mc 200 -of json -o "$defaultOutputPath"';

  final prefs = await SharedPreferences.getInstance();
  final savedCommand = prefs.getString('ffuf_command') ?? defaultCommand;

  final resolvedCommand = savedCommand.replaceAll('DOMAIN', domain);

  final parts = tokenizeCommand(resolvedCommand);
  if (parts.isEmpty) {
    onLog?.call(l10n.logFfufEmpty);
    return foundSubdomains;
  }

  final ffufExec = resolveExec(parts.first, 'ffuf');

  final args = <String>[];
  args.addAll(parts.skip(1));

  // Locate the -o argument so we know where to read the JSON output from.
  String? outputPath;
  for (int i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '-o' && i + 1 < args.length) {
      outputPath = args[i + 1];
      break;
    }
  }

  // If no -o was specified in the command, inject one pointing at the temp dir.
  if (outputPath == null) {
    outputPath = defaultOutputPath;
    args.addAll(['-of', 'json', '-o', outputPath]);
  }

  onLog?.call(l10n.logFfufRunning('$ffufExec ${args.join(' ')}'));

  late ProcessResult proc;
  try {
    proc = await Process.run(ffufExec, args, runInShell: false);
  } catch (e) {
    onLog?.call(l10n.logFfufStartFailed(e));
    return foundSubdomains;
  }

  if (proc.exitCode != 0) {
    final err =
        (proc.stderr is String) ? proc.stderr as String : '${proc.stderr}';
    onLog?.call(l10n.logFfufError(proc.exitCode));
    if (err.trim().isNotEmpty) onLog?.call(err.trim());
    return foundSubdomains;
  }

  final outFile = File(outputPath);
  if (!await outFile.exists()) {
    onLog?.call(l10n.logFfufOutputNotFound(outFile.path));
    return foundSubdomains;
  }

  try {
    final data = jsonDecode(await outFile.readAsString());
    final results =
        (data is Map && data['results'] is List)
            ? (data['results'] as List)
            : const [];

    for (final r in results) {
      if (r is! Map) continue;
      final url = r['url'] is String ? r['url'] as String : null;
      if (url == null) continue;

      final host =
          url
              .replaceAll(RegExp(r'^https?://', caseSensitive: false), '')
              .split('/')
              .first;
      if (host == domain || host.endsWith('.$domain')) {
        foundSubdomains.add(host);
      }
    }

    onLog?.call(l10n.logFfufFound(foundSubdomains.length));
  } catch (e) {
    onLog?.call(l10n.logFfufJsonError(e));
  }

  // Clean up the temp output file.
  try {
    if (await outFile.exists()) await outFile.delete();
  } catch (_) {}

  return foundSubdomains;
}
