import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/core/constants.dart';

void main() {
  group('Forbidden Words Scanner - Backup & Restore', () {
    test('lib/features/backup/ contains zero forbidden regulatory words', () {
      final backupDir = Directory('lib/features/backup');
      expect(backupDir.existsSync(), isTrue, reason: 'lib/features/backup directory must exist');

      final dartFiles = backupDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final violations = <String>[];

      for (final file in dartFiles) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          final trimmed = line.trim();
          if (trimmed.startsWith('//') || trimmed.startsWith('///') || trimmed.startsWith('*')) {
            continue;
          }
          final lower = line.toLowerCase();
          for (final word in kForbiddenClaimWords) {
            if (lower.contains(word)) {
              violations.add('${file.path}:${i + 1} contains "$word": $line');
            }
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Forbidden words must never appear in backup code or strings:\n${violations.join("\n")}',
      );
    });
  });
}
