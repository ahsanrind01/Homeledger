import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/rule_profile_loader.dart';

/// Test helper providing in-memory asset bundle for loading tests.
class TestAssetBundle extends AssetBundle {
  final Map<String, String> assets;

  TestAssetBundle(this.assets);

  @override
  Future<ByteData> load(String key) async {
    final str = assets[key];
    if (str == null) {
      throw Exception('Asset not found: $key');
    }
    final bytes = utf8.encode(str);
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final str = assets[key];
    if (str == null) {
      throw Exception('Asset not found: $key');
    }
    return str;
  }
}

void main() {
  group('RuleProfileLoader - Validation', () {
    test('valid profile passes validation', () {
      final validJson = {
        'id': 'test_rule',
        'label': 'Test Rule Profile',
        'requiredHours': 100,
        'requiredDays': 100,
        'coreSubjects': ['Math', 'Science'],
        'sourceUrl': 'https://example.com/law',
        'lastChecked': '2026-10-19',
        'notes': 'Test notes',
      };

      final error = RuleProfileLoader.validateProfileMap(validJson);
      expect(error, isNull);
    });

    test('hours-only profile passes validation', () {
      final json = {
        'id': 'hours_rule',
        'label': 'Hours Only Profile',
        'requiredHours': 900,
      };

      expect(RuleProfileLoader.validateProfileMap(json), isNull);
    });

    test('days-only profile passes validation', () {
      final json = {
        'id': 'days_rule',
        'label': 'Days Only Profile',
        'requiredDays': 180,
      };

      expect(RuleProfileLoader.validateProfileMap(json), isNull);
    });

    test('rejects empty or whitespace id with readable message', () {
      final emptyId = {
        'id': '   ',
        'label': 'Some Rule',
        'requiredHours': 100,
      };
      final missingId = {
        'label': 'Some Rule',
        'requiredHours': 100,
      };

      expect(
        RuleProfileLoader.validateProfileMap(emptyId),
        contains('Profile id must be a non-empty string'),
      );
      expect(
        RuleProfileLoader.validateProfileMap(missingId),
        contains('Profile id must be a non-empty string'),
      );
    });

    test('rejects duplicate id with readable message', () {
      final json = {
        'id': 'existing_id',
        'label': 'Some Rule',
        'requiredHours': 100,
      };

      final error = RuleProfileLoader.validateProfileMap(
        json,
        existingIds: {'existing_id'},
      );
      expect(error, contains('Duplicate profile id: "existing_id"'));
    });

    test('rejects empty or whitespace label with readable message', () {
      final emptyLabel = {
        'id': 'rule_1',
        'label': '  ',
        'requiredHours': 100,
      };

      expect(
        RuleProfileLoader.validateProfileMap(emptyLabel),
        contains('Profile label must be a non-empty string for profile "rule_1"'),
      );
    });

    test('rejects profile when neither hours nor days are set or positive', () {
      final bothNull = {
        'id': 'rule_null',
        'label': 'Rule Null',
      };
      final bothZero = {
        'id': 'rule_zero',
        'label': 'Rule Zero',
        'requiredHours': 0,
        'requiredDays': 0,
      };

      expect(
        RuleProfileLoader.validateProfileMap(bothNull),
        contains(
            'must have at least one positive requirement (requiredHours > 0 or requiredDays > 0)'),
      );
      expect(
        RuleProfileLoader.validateProfileMap(bothZero),
        contains(
            'must have at least one positive requirement (requiredHours > 0 or requiredDays > 0)'),
      );
    });

    test('rejects negative hours or negative days with readable message', () {
      final negativeHours = {
        'id': 'neg_hours',
        'label': 'Negative Hours',
        'requiredHours': -10,
        'requiredDays': 100,
      };
      final negativeDays = {
        'id': 'neg_days',
        'label': 'Negative Days',
        'requiredHours': 100,
        'requiredDays': -5,
      };

      expect(
        RuleProfileLoader.validateProfileMap(negativeHours),
        contains('requiredHours cannot be negative for profile "neg_hours"'),
      );
      expect(
        RuleProfileLoader.validateProfileMap(negativeDays),
        contains('requiredDays cannot be negative for profile "neg_days"'),
      );
    });

    test('rejects invalid lastChecked date format or non-existent date', () {
      final wrongFormat = {
        'id': 'bad_date_format',
        'label': 'Bad Date',
        'requiredHours': 100,
        'lastChecked': '10-19-2026',
      };
      final nonExistentDate = {
        'id': 'bad_feb_30',
        'label': 'Bad Feb Date',
        'requiredHours': 100,
        'lastChecked': '2026-02-30',
      };
      final invalidMonth = {
        'id': 'bad_month',
        'label': 'Bad Month Date',
        'requiredHours': 100,
        'lastChecked': '2026-13-01',
      };

      expect(
        RuleProfileLoader.validateProfileMap(wrongFormat),
        contains('is not a valid date (must be YYYY-MM-DD)'),
      );
      expect(
        RuleProfileLoader.validateProfileMap(nonExistentDate),
        contains('is not a valid date (must be YYYY-MM-DD)'),
      );
      expect(
        RuleProfileLoader.validateProfileMap(invalidMonth),
        contains('is not a valid date (must be YYYY-MM-DD)'),
      );
    });
  });

  group('RuleProfileLoader - Asset Loading & Error Resilience', () {
    test('loads valid profile successfully from index', () async {
      final bundle = TestAssetBundle({
        'assets/rules/index.json': jsonEncode(['rule_alpha.json']),
        'assets/rules/rule_alpha.json': jsonEncode({
          'id': 'rule_alpha',
          'label': 'Alpha Rule',
          'requiredHours': 200,
          'requiredDays': null,
          'coreSubjects': ['Math'],
          'sourceUrl': null,
          'lastChecked': '2026-10-19',
          'notes': 'Alpha note',
        }),
      });

      final loader = RuleProfileLoader(assetBundle: bundle);
      final result = await loader.loadProfiles();

      expect(result.errors, isEmpty);
      expect(result.profiles.length, 1);
      expect(result.profiles.first.id, 'rule_alpha');
      expect(result.profiles.first.requiredHours, 200);
    });

    test('malformed JSON file does not stop other profiles from loading',
        () async {
      final bundle = TestAssetBundle({
        'assets/rules/index.json': jsonEncode([
          'corrupted.json',
          'valid_one.json',
          'invalid_values.json',
          'valid_two.json',
        ]),
        'assets/rules/corrupted.json': '{{{ NOT VALID JSON }}}',
        'assets/rules/valid_one.json': jsonEncode({
          'id': 'valid_one',
          'label': 'Valid One',
          'requiredHours': 500,
        }),
        'assets/rules/invalid_values.json': jsonEncode({
          'id': 'invalid_values',
          'label': 'Invalid Values',
          'requiredHours': -99, // Negative hours
        }),
        'assets/rules/valid_two.json': jsonEncode({
          'id': 'valid_two',
          'label': 'Valid Two',
          'requiredDays': 180,
        }),
      });

      final loader = RuleProfileLoader(assetBundle: bundle);
      final result = await loader.loadProfiles();

      // Successfully loaded the two valid profiles
      expect(result.profiles.length, 2);
      expect(result.profiles.map((p) => p.id), ['valid_one', 'valid_two']);

      // Recorded readable error messages for corrupted and invalid profiles
      expect(result.errors.length, 2);
      expect(result.errors[0], contains('is not valid JSON'));
      expect(result.errors[1], contains('requiredHours cannot be negative'));
    });

    test('missing profile file in bundle reports error without crashing',
        () async {
      final bundle = TestAssetBundle({
        'assets/rules/index.json': jsonEncode(['non_existent.json']),
      });

      final loader = RuleProfileLoader(assetBundle: bundle);
      final result = await loader.loadProfiles();

      expect(result.profiles, isEmpty);
      expect(result.errors.length, 1);
      expect(result.errors.first, contains('Failed to load profile asset'));
    });

    test('missing index.json reports error without crashing', () async {
      final bundle = TestAssetBundle({});
      final loader = RuleProfileLoader(assetBundle: bundle);
      final result = await loader.loadProfiles();

      expect(result.profiles, isEmpty);
      expect(result.errors.length, 1);
      expect(result.errors.first, contains('Failed to read index file'));
    });
  });
}
