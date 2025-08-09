import 'package:flutter/material.dart';
import '../../models/scan_record.dart';

class DetailsHeader extends StatelessWidget {
  final ScanRecord record;
  const DetailsHeader({Key? key, required this.record}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              record.domain,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _chip(context, 'Status: ${record.status}'),
                _chip(context, 'Início: ${record.startedAt}'),
                _chip(context, 'Fim: ${record.finishedAt ?? '—'}'),
                _chip(context, 'Subdomínios: ${record.subdomainsFound}'),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText('Diretório: ${record.outputDir ?? '—'}'),
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceVariant,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(text, style: const TextStyle(fontSize: 12)),
  );
}
