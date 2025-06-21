import 'package:flutter/material.dart';
import '../services/scan_service.dart';

class ScanViewModel extends ChangeNotifier {
  final ScanService _scanService = ScanService();

  List<String> subdomains = [];
  List<String> logs = [];
  bool isLoading = false;

  Future<void> scan(String domain) async {
    isLoading = true;
    logs = ['[*] Iniciando escaneamento...'];
    notifyListeners();

    try {
      final (resultSet, resultLogs) = await _scanService.scanDomain(domain);
      subdomains = resultSet.toList()..sort();
      logs = resultLogs;
    } catch (e) {
      logs.add('[-] Erro: $e');
    }

    isLoading = false;
    notifyListeners();
  }
}
