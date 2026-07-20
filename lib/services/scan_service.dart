import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../l10n/app_localizations.dart';
import '../repositories/scan_history_repository.dart';
import '../models/scan_record.dart';
import '../utils/input_validation.dart';
import '../utils/juicy_targets.dart';
import '../utils/save_results.dart';
import 'scan/assetfinder_scan.dart';
import 'scan/crtsh_scan.dart';
import 'scan/ffuf_scan.dart';
import 'scan/gowitness_scan.dart';
import 'scan/httprobe_scan.dart';
import 'scan/subfinder_scan.dart';
import 'tool_installer.dart';

class ScanService {
  Future<(Set<String>, List<String>)> scanDomainWithProgress(
    String domain,
    AppLocalizations l10n, {
    void Function(String log)? onLog,
    void Function()? onHttprobeStart,
    void Function(int current, int total)? onHttprobeProgress,
    void Function()? onHttprobeEnd,
  }) async {
    final Set<String> allSubdomains = {};
    final List<String> activeList = [];
    final startedAt = DateTime.now();

    // Valida e normaliza. Rejeita espaços, aspas e metacaracteres que
    // permitiriam injeção de argumento no comando do ffuf (DOMAIN é
    // interpolado numa string de comando e depois tokenizado por espaço).
    final baseDomain = validateAndNormalizeDomain(domain);

    // Garante que os binários existam antes de rodar. Baixa os faltantes das
    // releases fixadas, reportando progresso no log da UI.
    final installer = ToolInstaller();
    final missing = await installer.missing();
    if (missing.isNotEmpty) {
      onLog?.call(l10n.logDownloadingTools(missing.join(', ')));
      final errors = await installer.installMissing(
        onProgress: (tool, received, total) {
          if (total > 0 && received == total) {
            onLog?.call(l10n.logToolDownloaded(tool));
          }
        },
      );
      for (final entry in errors.entries) {
        onLog?.call(l10n.logToolDownloadFailed(entry.key, entry.value));
      }
    }

    // Subfinder
    final subfinderCount = await runSubfinder(
      domain: baseDomain,
      accumulator: allSubdomains,
      l10n: l10n,
      onLog: onLog,
    );
    onLog?.call(l10n.logSubfinderFound(subfinderCount));

    // Assetfinder
    final assetfinderCount = await runAssetfinder(
      domain: baseDomain,
      accumulator: allSubdomains,
      l10n: l10n,
      onLog: onLog,
    );
    onLog?.call(l10n.logAssetfinderFound(assetfinderCount));

    // crt.sh
    await runCrtsh(
      domain: baseDomain,
      accumulator: allSubdomains,
      l10n: l10n,
      onLog: onLog,
    );

    // FFUF
    final ffufSubdomains =
        await runFfufSubdomainScan(baseDomain, l10n: l10n, onLog: onLog);
    allSubdomains.addAll(ffufSubdomains);
    onLog?.call(l10n.logFfufAdded(ffufSubdomains.length));

    // httprobe
    final active = await runHttprobe(
      subdomains: allSubdomains,
      l10n: l10n,
      onLog: onLog,
      onStart: onHttprobeStart,
      onProgress: onHttprobeProgress,
      onEnd: onHttprobeEnd,
    );
    activeList.addAll(active);

    onLog?.call(l10n.logTotalUnique(allSubdomains.length));

    // Save results to disk.
    final scanDir = await saveResults(
      allSubdomains,
      activeList.toSet(),
      l10n: l10n,
      onLog: onLog,
    );

    // Identify and persist juicy targets.
    final juicyTargets = identifyJuicyTargets(activeList);
    if (juicyTargets.isNotEmpty) {
      try {
        final juicyFile = File(p.join(scanDir.path, 'juicy_targets.txt'));
        await juicyFile.writeAsString(juicyTargets.join('\n'));
        onLog?.call(l10n.logJuicySaved(juicyFile.path));
      } catch (e) {
        onLog?.call(l10n.logJuicySaveFailed(e));
      }
    }

    // gowitness
    if (activeList.isNotEmpty) {
      await runGowitness(
        activeSubdomains: activeList,
        scanDirectory: scanDir,
        l10n: l10n,
        onLog: onLog,
      );
    }

    const divider =
        '-----------------------------------------------------------';
    onLog?.call(divider);
    onLog?.call(l10n.logSummaryHeader);
    onLog?.call(divider);
    onLog?.call(l10n.logSummaryUnique(allSubdomains.length));
    onLog?.call(l10n.logSummaryActive(activeList.length));
    onLog?.call(l10n.logSummaryJuicy(juicyTargets.length));
    onLog?.call(
      l10n.logSummaryScreenshots(activeList.isNotEmpty ? l10n.yes : l10n.no),
    );
    onLog?.call(l10n.logSummaryDir(scanDir.path));
    onLog?.call(divider);

    try {
      final repo = ScanHistoryRepository();
      await repo.append(
        ScanRecord(
          id: const Uuid().v4(),
          domain: baseDomain,
          startedAt: startedAt,
          finishedAt: DateTime.now(),
          subdomainsFound: allSubdomains.length,
          status: 'success',
          outputDir: scanDir.path,
        ),
      );
      onLog?.call(l10n.logHistoryUpdated);
    } catch (e) {
      onLog?.call(l10n.logHistoryFailed(e));
    }

    return (allSubdomains, activeList);
  }
}
