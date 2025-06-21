import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/scan_viewmodel.dart';
import '../utils/log_utils.dart';

class ScanScreen extends StatelessWidget {
  final String domain;
  const ScanScreen({super.key, required this.domain});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ScanViewModel>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.scan(domain);
    });

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Scan de subdomínios'),
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
                  const Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Escaneando...', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                if (model.isRunningHttprobe &&
                    model.httprobeProgress != null) ...[
                  const Text(
                    'Verificando com httprobe...',
                    style: TextStyle(fontWeight: FontWeight.bold),
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
                if (!model.isLoading)
                  const Text(
                    'Log de execução:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
