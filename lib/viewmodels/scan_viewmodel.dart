import 'package:flutter/foundation.dart';
import '../services/scan_service.dart';

class ScanViewModel extends ChangeNotifier {
  final ScanService _scanService = ScanService();

  List<String> subdomains = [];
  List<String> activeSubdomains = [];
  List<String> logs = [];
  bool isLoading = false;

  Future<void> scan(String domain) async {
    isLoading = true;
    logs = ['[*] Iniciando escaneamento...'];
    notifyListeners();

    try {
      final (resultSet, _, activeList) = await _scanService.scanDomain(
        domain,
        onLog: (line) {
          logs.add(line);
          notifyListeners(); // 🔁 reatividade imediata!
        },
      );

      subdomains = resultSet.toList()..sort();
      activeSubdomains = activeList.toList()..sort();
    } catch (e) {
      logs.add('[-] Erro: $e');
    }

    isLoading = false;
    notifyListeners();
  }
}
