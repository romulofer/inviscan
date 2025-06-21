import 'package:flutter/foundation.dart';
import '../services/scan_service.dart';

class ScanViewModel extends ChangeNotifier {
  final ScanService _scanService = ScanService();

  List<String> subdomains = [];
  List<String> activeSubdomains = [];
  List<String> logs = [];

  bool isLoading = false;
  bool isRunningHttprobe = false;
  double? httprobeProgress;

  Future<void> scan(String domain) async {
    isLoading = true;
    logs = [];
    subdomains = [];
    activeSubdomains = [];
    isRunningHttprobe = false;
    httprobeProgress = null;
    notifyListeners();

    final List<String> logsLocal = [];

    void handleLog(String log) {
      logsLocal.add(log);
      logs = List.from(logsLocal);
      notifyListeners();
    }

    void handleHttprobeProgress(int current, int total) {
      httprobeProgress = current / total;
      notifyListeners();
    }

    void handleHttprobeStart() {
      isRunningHttprobe = true;
      notifyListeners();
    }

    void handleHttprobeEnd() {
      isRunningHttprobe = false;
      httprobeProgress = null;
      notifyListeners();
    }

    try {
      final (all, activeList) = await _scanService.scanDomainWithProgress(
        domain,
        onLog: handleLog,
        onHttprobeStart: handleHttprobeStart,
        onHttprobeProgress: handleHttprobeProgress,
        onHttprobeEnd: handleHttprobeEnd,
      );

      subdomains = all.toList();
      subdomains.sort();
      activeSubdomains = activeList;
    } catch (e) {
      handleLog('[-] Erro: $e');
    }

    isLoading = false;
    notifyListeners();
  }
}
