import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/scan_record.dart';
import '../repositories/scan_history_repository.dart';
import '../screens/scan_details_screen.dart';

class PreviousScansList extends StatefulWidget {
  const PreviousScansList({Key? key}) : super(key: key);

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
  }

  Future<void> _refresh() async {
    final items = await _repo.getAll();
    if (!mounted) return;
    setState(() => _future = Future.value(items));
  }

  Widget _statusChip(String status) {
    ColorScheme cs = Theme.of(context).colorScheme;
    Color bg;
    switch (status) {
      case 'running':
        bg = cs.secondaryContainer;
        break;
      case 'failed':
        bg = cs.errorContainer;
        break;
      default:
        bg = cs.primaryContainer;
    }
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
    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Scans anteriores',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  tooltip: 'Atualizar',
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                ),
                IconButton(
                  tooltip: 'Limpar histórico',
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder:
                          (_) => AlertDialog(
                            title: const Text('Limpar histórico?'),
                            content: const Text(
                              'Isso removerá todos os registros locais.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancelar'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Limpar'),
                              ),
                            ],
                          ),
                    );
                    if (ok == true) {
                      await _repo.clear();
                      await _refresh();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Histórico limpo.')),
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
                    child: Text('Erro ao carregar histórico: ${snap.error}'),
                  );
                }
                final items = snap.data ?? [];
                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Nenhum scan registrado ainda.'),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final r = items[i];
                    final started = _fmt.format(r.startedAt);
                    final finished =
                        r.finishedAt != null ? _fmt.format(r.finishedAt!) : '—';
                    return ListTile(
                      leading: const Icon(Icons.search),
                      title: Text(r.domain),
                      subtitle: Text(
                        'Início: $started  •  Fim: $finished\nSubdomínios: ${r.subdomainsFound}',
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
                                title: const Text('Remover este item?'),
                                content: Text('Domínio: ${r.domain}'),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.pop(context, false),
                                    child: const Text('Cancelar'),
                                  ),
                                  ElevatedButton(
                                    onPressed:
                                        () => Navigator.pop(context, true),
                                    child: const Text('Remover'),
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
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
