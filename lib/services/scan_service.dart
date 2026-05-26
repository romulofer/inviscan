import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../repositories/scan_history_repository.dart';
import '../models/scan_record.dart';
import '../utils/juicy_targets.dart';
import '../utils/save_results.dart';
import 'scan/assetfinder_scan.dart';
import 'scan/crtsh_scan.dart';
import 'scan/ffuf_scan.dart';
import 'scan/gowitness_scan.dart';
import 'scan/httprobe_scan.dart';
import 'scan/subfinder_scan.dart';

String _normalizeDomain(String input) {
  var d = input.trim();
  d = d.replaceAll(RegExp(r'^https?://', caseSensitive: false), '');
  d = d.split('/').first;
  return d;
}

class ScanService {
  Future<(Set<String>, List<String>)> scanDomainWithProgress(
    String domain, {
    void Function(String log)? onLog,
    void Function()? onHttprobeStart,
    void Function(int current, int total)? onHttprobeProgress,
    void Function()? onHttprobeEnd,
  }) async {
    final Set<String> allSubdomains = {};
    final List<String> activeList = [];
    final startedAt = DateTime.now();

    final baseDomain = _normalizeDomain(domain);

    // Subfinder
    final subfinderCount = await runSubfinder(
      domain: baseDomain,
      accumulator: allSubdomains,
      onLog: onLog,
    );
    onLog?.call('[+] subfinder encontrou $subfinderCount subdomínios.');

    // Assetfinder
    final assetfinderCount = await runAssetfinder(
      domain: baseDomain,
      accumulator: allSubdomains,
      onLog: onLog,
    );
    onLog?.call('[+] assetfinder encontrou $assetfinderCount subdomínios.');

    // crt.sh
    await runCrtsh(
      domain: baseDomain,
      accumulator: allSubdomains,
      onLog: onLog,
    );

    // FFUF
    final ffufSubdomains = await runFfufSubdomainScan(baseDomain, onLog: onLog);
    allSubdomains.addAll(ffufSubdomains);
    onLog?.call('[+] ffuf adicionou ${ffufSubdomains.length} subdomínios.');

    // httprobe
    final active = await runHttprobe(
      subdomains: allSubdomains,
      onLog: onLog,
      onStart: onHttprobeStart,
      onProgress: onHttprobeProgress,
      onEnd: onHttprobeEnd,
    );
    activeList.addAll(active);

    onLog?.call(
      '[+] Total de subdomínios únicos encontrados: ${allSubdomains.length}',
    );

    // Save results to disk.
    final scanDir = await saveResults(
      allSubdomains,
      activeList.toSet(),
      onLog: onLog,
    );

    // Identify and persist juicy targets.
    final juicyTargets = identifyJuicyTargets(activeList);
    if (juicyTargets.isNotEmpty) {
      try {
        final juicyFile = File(p.join(scanDir.path, 'juicy_targets.txt'));
        await juicyFile.writeAsString(juicyTargets.join('\n'));
        onLog?.call('[+] Juicy targets salvos em: ${juicyFile.path}');
      } catch (e) {
        onLog?.call('[-] Falha ao salvar juicy targets: $e');
      }
    }

    // gowitness
    if (activeList.isNotEmpty) {
      await runGowitness(
        activeSubdomains: activeList,
        scanDirectory: scanDir,
        onLog: onLog,
      );
    }

    onLog?.call('-----------------------------------------------------------');
    onLog?.call('[Resumo das descobertas]');
    onLog?.call('-----------------------------------------------------------');
    onLog?.call('→ Subdomínios únicos encontrados: ${allSubdomains.length}');
    onLog?.call('→ Subdomínios ativos identificados: ${activeList.length}');
    onLog?.call('→ Juicy Targets encontrados: ${juicyTargets.length}');
    onLog?.call(
      '→ Screenshots salvos: ${activeList.isNotEmpty ? 'Sim' : 'Não'}',
    );
    onLog?.call('→ Diretório do scan: ${scanDir.path}');
    onLog?.call('-----------------------------------------------------------');

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
      onLog?.call('[✓] Histórico atualizado.');
    } catch (e) {
      onLog?.call('[-] Falha ao atualizar histórico: $e');
    }

    return (allSubdomains, activeList);
  }
}
