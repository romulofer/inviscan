import 'dart:convert';

class ScanRecord {
  final String id;
  final String domain;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final int subdomainsFound;
  final String status;
  final String? outputDir;

  ScanRecord({
    required this.id,
    required this.domain,
    required this.startedAt,
    this.finishedAt,
    required this.subdomainsFound,
    required this.status,
    this.outputDir,
  });

  factory ScanRecord.fromMap(Map<String, dynamic> m) => ScanRecord(
    id: m['id'] as String,
    domain: m['domain'] as String,
    startedAt: DateTime.parse(m['startedAt'] as String),
    finishedAt:
        m['finishedAt'] != null ? DateTime.parse(m['finishedAt']) : null,
    subdomainsFound: (m['subdomainsFound'] ?? 0) as int,
    status: m['status'] as String? ?? 'success',
    outputDir: m['outputDir'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'domain': domain,
    'startedAt': startedAt.toIso8601String(),
    'finishedAt': finishedAt?.toIso8601String(),
    'subdomainsFound': subdomainsFound,
    'status': status,
    'outputDir': outputDir,
  };

  static List<ScanRecord> listFromJson(String jsonStr) {
    if (jsonStr.trim().isEmpty) return [];
    final data = json.decode(jsonStr) as List;
    return data
        .map((e) => ScanRecord.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  static String listToJson(List<ScanRecord> items) {
    return json.encode(items.map((e) => e.toMap()).toList());
  }
}
