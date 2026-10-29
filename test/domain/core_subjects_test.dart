import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/db/app_database.dart';
import 'package:homeledger/domain/core_subjects.dart';

void main() {
  group('coreSubjectsFor', () {
    test('returns empty list when no subject is core', () {
      final subjects = [
        const Subject(id: 1, name: 'Art', isCore: false, sortOrder: 0),
        const Subject(id: 2, name: 'Physical Education', isCore: false, sortOrder: 1),
        const Subject(id: 3, name: 'Music', isCore: false, sortOrder: 2),
      ];

      final result = coreSubjectsFor(subjects);
      expect(result, isEmpty);
    });

    test('returns all subjects when all subjects are core', () {
      final subjects = [
        const Subject(id: 1, name: 'Math', isCore: true, sortOrder: 0),
        const Subject(id: 2, name: 'Reading', isCore: true, sortOrder: 1),
        const Subject(id: 3, name: 'Science', isCore: true, sortOrder: 2),
        const Subject(id: 4, name: 'Social Studies', isCore: true, sortOrder: 3),
      ];

      final result = coreSubjectsFor(subjects);
      expect(result.length, 4);
      expect(result.map((s) => s.name), equals(['Math', 'Reading', 'Science', 'Social Studies']));
    });

    test('returns only core subjects in a mixed list', () {
      final subjects = [
        const Subject(id: 1, name: 'Math', isCore: true, sortOrder: 0),
        const Subject(id: 2, name: 'Art', isCore: false, sortOrder: 1),
        const Subject(id: 3, name: 'Language Arts', isCore: true, sortOrder: 2),
        const Subject(id: 4, name: 'Drama', isCore: false, sortOrder: 3),
      ];

      final result = coreSubjectsFor(subjects);
      expect(result.length, 2);
      expect(result.map((s) => s.name), equals(['Math', 'Language Arts']));
    });

    test('correctly identifies a core subject after it was renamed', () {
      // Original core subject
      const original = Subject(id: 1, name: 'Math', isCore: true, sortOrder: 0);
      expect(isCoreSubject(original), isTrue);

      // Renamed to 'Pre-Calculus', preserving isCore = true
      final renamed = original.copyWith(name: 'Pre-Calculus');
      final subjects = [
        renamed,
        const Subject(id: 2, name: 'Art', isCore: false, sortOrder: 1),
      ];

      final result = coreSubjectsFor(subjects);
      expect(result.length, 1);
      expect(result.first.name, 'Pre-Calculus');
      expect(result.first.id, 1);
      expect(isCoreSubject(renamed), isTrue);
    });

    test('correctly identifies non-core subject renamed to a traditional core name', () {
      // Non-core elective renamed to 'Math' but isCore remains false
      const elective = Subject(id: 5, name: 'Music', isCore: false, sortOrder: 4);
      final renamed = elective.copyWith(name: 'Math');

      final result = coreSubjectsFor([renamed]);
      expect(result, isEmpty);
      expect(isCoreSubject(renamed), isFalse);
    });
  });

  group('formatCoreStatus', () {
    test('formats true as Yes and false as No', () {
      expect(formatCoreStatus(true), 'Yes');
      expect(formatCoreStatus(false), 'No');
    });
  });
}
