import '../utils/juicy_targets.dart';
import '../utils/save_results.dart';
import 'scan/assetfinder_scan.dart';
import 'scan/crtsh_scan.dart';
import 'scan/ffuf_scan.dart';
import 'scan/gowitness_scan.dart';
import 'scan/httprobe_scan.dart';
import 'scan/subfinder_scan.dart';

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
    final baseDomain = domain.trim();

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
    final crtshCount = await runCrtsh(
      domain: baseDomain,
      accumulator: allSubdomains,
      onLog: onLog,
    );
    onLog?.call('[+] crt.sh encontrou $crtshCount subdomínios.');

    // FFUF
    final ffufSubdomains = await runFfufSubdomainScan(baseDomain, onLog: onLog);
    allSubdomains.addAll(ffufSubdomains);
    onLog?.call('[+] ffuf adicionou ${ffufSubdomains.length} subdomínios.');

    // httprobe
    onLog?.call('[*] Iniciando verificação com httprobe...');
    onHttprobeStart?.call();

    final active = await runHttprobe(
      subdomains: allSubdomains,
      onLog: onLog,
      onProgress: onHttprobeProgress,
    );

    activeList.addAll(active);
    onHttprobeEnd?.call();

    onLog?.call(
      '[+] httprobe identificou ${activeList.length} subdomínios ativos.',
    );
    onLog?.call(
      '[+] Total de subdomínios únicos encontrados: ${allSubdomains.length}',
    );

    // Salvando resultados
    final scanDir = await saveResults(
      allSubdomains,
      allSubdomains.toSet(),
      activeList.toSet(),
    );

    // gowitness
    if (activeList.isNotEmpty) {
      await runGowitness(
        activeSubdomains: activeList,
        scanDirectory: scanDir,
        onLog: onLog,
      );
    }

    // juicy targets
    final juicyTargets = await identifyJuicyTargets(activeList);

    // resumo
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

    return (allSubdomains, activeList);
  }
}
