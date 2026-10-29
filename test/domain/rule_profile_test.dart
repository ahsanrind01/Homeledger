import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/domain/rule_profile.dart';

void main() {
  group('RuleProfile', () {
    test('creates and serializes a valid RuleProfile with both hours and days',
        () {
      const profile = RuleProfile(
        id: 'placeholder_example',
        label: 'Example profile (not a real state)',
        requiredHours: 100,
        requiredDays: 100,
        coreSubjects: ['Math', 'Reading'],
        sourceUrl: null,
        lastChecked: '2026-10-19',
        isCustom: false,
        notes: 'Test notes',
      );

      expect(profile.id, 'placeholder_example');
      expect(profile.label, 'Example profile (not a real state)');
      expect(profile.requiredHours, 100);
      expect(profile.requiredDays, 100);
      expect(profile.coreSubjects, ['Math', 'Reading']);
      expect(profile.sourceUrl, isNull);
      expect(profile.lastChecked, '2026-10-19');
      expect(profile.isCustom, isFalse);
      expect(profile.notes, 'Test notes');

      final json = profile.toJson();
      final deserialized = RuleProfile.fromJson(json);
      expect(deserialized, equals(profile));
    });

    test('hours-only profile is valid', () {
      const profile = RuleProfile(
        id: 'hours_only',
        label: 'Hours Only Rule',
        requiredHours: 900,
        requiredDays: null,
      );

      expect(profile.requiredHours, 900);
      expect(profile.requiredDays, isNull);
    });

    test('days-only profile is valid', () {
      const profile = RuleProfile(
        id: 'days_only',
        label: 'Days Only Rule',
        requiredHours: null,
        requiredDays: 180,
      );

      expect(profile.requiredHours, isNull);
      expect(profile.requiredDays, 180);
    });

    test('equality checks work for identical and distinct profiles', () {
      const p1 = RuleProfile(
        id: 'test',
        label: 'Test Rule',
        requiredHours: 100,
        coreSubjects: ['Math'],
      );

      const p2 = RuleProfile(
        id: 'test',
        label: 'Test Rule',
        requiredHours: 100,
        coreSubjects: ['Math'],
      );

      const p3 = RuleProfile(
        id: 'test2',
        label: 'Test Rule 2',
        requiredHours: 100,
        coreSubjects: ['Math'],
      );

      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
      expect(p1, isNot(equals(p3)));
    });

    test('asserts when both hours and days are null', () {
      expect(
        () => RuleProfile(
          id: 'invalid',
          label: 'No hours or days',
          requiredHours: null,
          requiredDays: null,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('asserts when both hours and days are zero or negative', () {
      expect(
        () => RuleProfile(
          id: 'invalid',
          label: 'Zero hours and days',
          requiredHours: 0,
          requiredDays: 0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('asserts when id is empty', () {
      expect(
        () => RuleProfile(
          id: '',
          label: 'Valid label',
          requiredHours: 100,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('asserts when label is empty', () {
      expect(
        () => RuleProfile(
          id: 'valid_id',
          label: '',
          requiredHours: 100,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('asserts when requiredHours is negative', () {
      expect(
        () => RuleProfile(
          id: 'negative_hours',
          label: 'Negative hours',
          requiredHours: -10,
          requiredDays: 100,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('asserts when requiredDays is negative', () {
      expect(
        () => RuleProfile(
          id: 'negative_days',
          label: 'Negative days',
          requiredHours: 100,
          requiredDays: -5,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
