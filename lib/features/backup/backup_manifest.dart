import 'dart:convert';

/// Record count metadata stored inside manifest.json.
class BackupCounts {
  final int children;
  final int entries;
  final int samples;

  const BackupCounts({
    required this.children,
    required this.entries,
    required this.samples,
  });

  Map<String, dynamic> toJson() => {
        'children': children,
        'entries': entries,
        'samples': samples,
      };

  factory BackupCounts.fromJson(Map<String, dynamic> json) {
    return BackupCounts(
      children: (json['children'] as num?)?.toInt() ?? 0,
      entries: (json['entries'] as num?)?.toInt() ?? 0,
      samples: (json['samples'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Metadata structure stored as `manifest.json` inside every backup archive.
class BackupManifest {
  final int schemaVersion;
  final String appVersion;
  final String createdAt;
  final BackupCounts counts;

  const BackupManifest({
    required this.schemaVersion,
    required this.appVersion,
    required this.createdAt,
    required this.counts,
  });

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'appVersion': appVersion,
        'createdAt': createdAt,
        'counts': counts.toJson(),
      };

  String toRawJson() => const JsonEncoder.withIndent('  ').convert(toJson());

  factory BackupManifest.fromJson(Map<String, dynamic> json) {
    final schema = (json['schemaVersion'] as num?)?.toInt();
    if (schema == null) {
      throw const FormatException('manifest.json is missing required "schemaVersion" field.');
    }
    final appVer = json['appVersion'] as String? ?? '1.0.0';
    final created = json['createdAt'] as String? ?? '1970-01-01T00:00:00.000Z';
    final countsMap = json['counts'] as Map<String, dynamic>? ?? {};

    return BackupManifest(
      schemaVersion: schema,
      appVersion: appVer,
      createdAt: created,
      counts: BackupCounts.fromJson(countsMap),
    );
  }

  factory BackupManifest.fromRawJson(String rawJson) {
    final decoded = json.decode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('manifest.json root must be a JSON object.');
    }
    return BackupManifest.fromJson(decoded);
  }
}
