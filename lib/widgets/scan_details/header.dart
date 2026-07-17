import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/scan_record.dart';

class DetailsHeader extends StatelessWidget {
  final ScanRecord record;
  const DetailsHeader({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                _chip(context, l10n.statusChip(record.status)),
                _chip(context, l10n.startedChip('${record.startedAt}')),
                _chip(context, l10n.finishedChip('${record.finishedAt ?? '—'}')),
                _chip(context, l10n.subdomainsChip(record.subdomainsFound)),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(l10n.directoryLabel(record.outputDir ?? '—')),
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(text, style: const TextStyle(fontSize: 12)),
  );
}
