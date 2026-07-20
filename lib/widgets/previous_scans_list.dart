import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../models/scan_record.dart';
import '../repositories/scan_history_repository.dart';
import '../screens/scan_details_screen.dart';

class PreviousScansList extends StatefulWidget {
  const PreviousScansList({super.key, this.maxHeight = 420});
  final double maxHeight;

  @override
  State<PreviousScansList> createState() => _PreviousScansListState();
}

class _PreviousScansListState extends State<PreviousScansList> {
  final _repo = ScanHistoryRepository();
  late Future<List<ScanRecord>> _future;
  final _fmt = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _future = _repo.getAll();
    ScanHistoryRepository.revision.addListener(_onRevisionChanged);
  }

  void _onRevisionChanged() => _reload();

  Future<void> _reload() async {
    final items = await _repo.getAll();
    if (!mounted) return;
    setState(() {
      _future = Future.value(items);
    });
  }

  Future<void> _refresh() => _reload();

  @override
  void dispose() {
    ScanHistoryRepository.revision.removeListener(_onRevisionChanged);
    super.dispose();
  }

  Widget _statusChip(String status) {
    final cs = Theme.of(context).colorScheme;
    final bg = switch (status) {
      'running' => cs.secondaryContainer,
      'failed' => cs.errorContainer,
      _ => cs.primaryContainer,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(status, style: const TextStyle(fontSize: 12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.previousScans,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  tooltip: l10n.refresh,
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                ),
                IconButton(
                  tooltip: l10n.clearHistory,
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder:
                          (_) => AlertDialog(
                            title: Text(l10n.clearHistoryQuestion),
                            content: Text(l10n.clearHistoryConfirm),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(l10n.cancel),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(l10n.clearAction),
                              ),
                            ],
                          ),
                    );
                    if (ok == true) {
                      await _repo.clear();
                      await _refresh();
                      if (!mounted) return;
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.historyCleared)),
                      );
                    }
                  },
                  icon: const Icon(Icons.delete_sweep),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<ScanRecord>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(l10n.loadHistoryError(snap.error!)),
                  );
                }
                final items = snap.data ?? [];
                if (items.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(l10n.noScansYet),
                  );
                }

                return SizedBox(
                  height: widget.maxHeight,
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final r = items[i];
                      final started = _fmt.format(r.startedAt);
                      final finished =
                          r.finishedAt != null
                              ? _fmt.format(r.finishedAt!)
                              : '—';
                      return ListTile(
                        leading: const Icon(Icons.search),
                        title: Text(r.domain),
                        subtitle: Text(
                          l10n.scanListSubtitle(
                            started,
                            finished,
                            r.subdomainsFound,
                          ),
                        ),
                        isThreeLine: true,
                        trailing: _statusChip(r.status),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ScanDetailsScreen(record: r),
                            ),
                          );
                        },
                        onLongPress: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder:
                                (_) => AlertDialog(
                                  title: Text(l10n.removeItemQuestion),
                                  content: Text(l10n.domainLabel(r.domain)),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, false),
                                      child: Text(l10n.cancel),
                                    ),
                                    ElevatedButton(
                                      onPressed:
                                          () => Navigator.pop(context, true),
                                      child: Text(l10n.remove),
                                    ),
                                  ],
                                ),
                          );
                          if (ok == true) {
                            await _repo.removeById(r.id);
                            await _refresh();
                          }
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
