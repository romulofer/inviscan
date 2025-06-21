import 'dart:io';
import 'package:flutter/material.dart';

class ScanScreen extends StatefulWidget {
  final String domain;

  const ScanScreen({super.key, required this.domain});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  List<String> subdomains = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    final baseDomain = widget.domain;

    final Set<String> results = {};

    try {
      final subfinder = await Process.run('subfinder', ['-d', baseDomain]);

      if (subfinder.exitCode == 0) {
        results.addAll(
          (subfinder.stdout as String)
              .split('\n')
              .where((e) => e.trim().isNotEmpty),
        );
      }

      final assetfinder = await Process.run('assetfinder', [
        '--subs-only',
        baseDomain,
      ]);

      if (assetfinder.exitCode == 0) {
        results.addAll(
          (assetfinder.stdout as String)
              .split('\n')
              .where((e) => e.trim().isNotEmpty),
        );
      }

      final crtsh = await Process.run('bash', [
        '-c',
        'curl -s https://crt.sh/?q=%25.$baseDomain&output=json',
      ]);
      if (crtsh.exitCode == 0) {
        final List<String> parsed =
            RegExp(r'"name_value"\s*:\s*"([^"]+)"')
                .allMatches(crtsh.stdout)
                .map((m) => m.group(1)!)
                .expand((e) => e.split('\n'))
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty && e.endsWith(baseDomain))
                .toSet()
                .toList();
        results.addAll(parsed);
      }
    } catch (e) {
      debugPrint('[-] Erro durante o scan: $e');
    }

    setState(() {
      subdomains = results.toList()..sort();
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Scan de subdomínios')),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : subdomains.isEmpty
              ? const Center(child: Text('Nenhum subdomínio encontrado.'))
              : ListView.builder(
                itemCount: subdomains.length,
                itemBuilder: (context, index) {
                  return ListTile(title: Text(subdomains[index]));
                },
              ),
    );
  }
}
