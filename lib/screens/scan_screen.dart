import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../viewmodels/scan_viewmodel.dart';
import '../utils/log_utils.dart';

class ScanScreen extends StatefulWidget {
  final String domain;
  const ScanScreen({super.key, required this.domain});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger the scan exactly once, after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ScanViewModel>().scan(
          widget.domain,
          AppLocalizations.of(context),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          l10n.scanSubdomainsTitle,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Consumer<ScanViewModel>(
        builder: (context, model, _) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (model.isLoading) ...[
                  Center(
                    child: Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 12),
                        Text(l10n.scanning,
                            style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                if (model.isRunningHttprobe &&
                    model.httprobeProgress != null) ...[
                  Text(
                    l10n.verifyingHttprobe,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: model.httprobeProgress!,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.deepPurple,
                    ),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 24),
                ],

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.executionLog,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          tooltip: l10n.copyLogs,
                          icon: const Icon(Icons.copy, size: 20),
                          onPressed:
                              model.logs.isEmpty
                                  ? null
                                  : () =>
                                      LogUtils.copyLogs(context, model.logs),
                        ),
                        IconButton(
                          tooltip: l10n.saveLogsToFile,
                          icon: const Icon(Icons.save_alt, size: 20),
                          onPressed:
                              model.logs.isEmpty
                                  ? null
                                  : () => LogUtils.saveLogs(
                                    context,
                                    model.logs,
                                    domain: widget.domain,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ListView.builder(
                      itemCount: model.logs.length,
                      itemBuilder: (context, index) {
                        final log = model.logs[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            log,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: LogUtils.getLogColor(log),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
