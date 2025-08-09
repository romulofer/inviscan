import 'dart:io';
import 'package:flutter/material.dart';

import '../models/scan_record.dart';
import '../widgets/scan_details/fs_helpers.dart';
import '../widgets/scan_details/header.dart';
import '../widgets/scan_details/juicy_targets_section.dart';
import '../widgets/scan_details/screenshots_section.dart';
import '../widgets/scan_details/artifacts_section.dart';

class ScanDetailsScreen extends StatefulWidget {
  final ScanRecord record;
  const ScanDetailsScreen({Key? key, required this.record}) : super(key: key);

  @override
  State<ScanDetailsScreen> createState() => _ScanDetailsScreenState();
}

class _ScanDetailsScreenState extends State<ScanDetailsScreen> {
  late final Directory? _scanDir =
      widget.record.outputDir != null
          ? Directory(widget.record.outputDir!)
          : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do scan'),
        actions: [
          if (_scanDir != null)
            IconButton(
              tooltip: 'Abrir pasta',
              onPressed: () => openExternally(context, _scanDir!),
              icon: const Icon(Icons.folder_open),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          DetailsHeader(record: widget.record),
          const SizedBox(height: 12),
          if (_scanDir != null) ...[
            JuicyTargetsSection(scanDir: _scanDir!),
            const SizedBox(height: 12),
            ScreenshotsSection(scanDir: _scanDir!),
            const SizedBox(height: 12),
            ArtifactsSection(scanDir: _scanDir!),
          ] else
            const Text('Sem diretório de saída para este scan.'),
        ],
      ),
    );
  }
}
