import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/db/app_database.dart';
import 'package:homeledger/data/repositories/custom_rule_repository.dart';
import 'package:homeledger/data/rule_profile_loader.dart';
import 'package:homeledger/data/rule_resolver.dart';
import 'package:homeledger/domain/rule_profile.dart';
import 'package:homeledger/domain/rule_resolution.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late CustomRuleRepository customRuleRepo;

  const placeholderProfile = RuleProfile(
    id: 'placeholder_example',
    label: 'Example profile (not a real state)',
    requiredHours: 100,
    requiredDays: 100,
    coreSubjects: ['Math', 'Reading'],
    sourceUrl: null,
    lastChecked: null,
    isCustom: false,
    notes: 'PLACEHOLDER. Replace with verified data before release.',
  );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    customRuleRepo = CustomRuleRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('RuleResolver', () {
    test('resolves standard asset profile by id', () async {
      final resolver = RuleResolver(
        customRuleRepository: customRuleRepo,
        assetProfiles: const [placeholderProfile],
      );

      final result = await resolver.resolve('placeholder_example');

      expect(result.isFound, isTrue);
      expect(result.isMissing, isFalse);
      expect(result.profileOrNull, equals(placeholderProfile));
      expect(result, isA<RuleResolutionFound>());
    });

    test('returns missing when standard profile id is unknown', () async {
      final resolver = RuleResolver(
        customRuleRepository: customRuleRepo,
        assetProfiles: const [placeholderProfile],
      );

      final result = await resolver.resolve('unknown_profile_id');

      expect(result.isMissing, isTrue);
      expect(result.isFound, isFalse);
      expect(result.profileOrNull, isNull);
      expect(result, isA<RuleResolutionMissing>());

      final missing = result as RuleResolutionMissing;
      expect(missing.ruleId, 'unknown_profile_id');
      expect(missing.message, contains('was not found'));
    });

    test('resolves custom rule by custom id prefix', () async {
      final customRowId = await customRuleRepo.add(
        CustomRulesCompanion.insert(
          label: 'Family Personal Target',
          requiredHours: const Value(800),
          requiredDays: const Value(160),
        ),
      );

      final resolver = RuleResolver(
        customRuleRepository: customRuleRepo,
        assetProfiles: const [placeholderProfile],
      );

      final result = await resolver.resolve('custom:$customRowId');

      expect(result.isFound, isTrue);
      expect(result.isMissing, isFalse);

      final profile = result.profileOrNull!;
      expect(profile.id, 'custom:$customRowId');
      expect(profile.label, 'Family Personal Target');
      expect(profile.requiredHours, 800);
      expect(profile.requiredDays, 160);
      expect(profile.isCustom, isTrue);
    });

    test('returns missing when custom rule id does not exist in database',
        () async {
      final resolver = RuleResolver(
        customRuleRepository: customRuleRepo,
        assetProfiles: const [placeholderProfile],
      );

      final result = await resolver.resolve('custom:9999');

      expect(result.isMissing, isTrue);
      expect(result.profileOrNull, isNull);

      final missing = result as RuleResolutionMissing;
      expect(missing.ruleId, 'custom:9999');
      expect(missing.message, contains('Custom rule #9999 was not found'));
    });

    test('returns missing when custom rule id format is non-numeric', () async {
      final resolver = RuleResolver(
        customRuleRepository: customRuleRepo,
        assetProfiles: const [placeholderProfile],
      );

      final result = await resolver.resolve('custom:abc');

      expect(result.isMissing, isTrue);
      final missing = result as RuleResolutionMissing;
      expect(missing.message, contains('is not a valid integer ID'));
    });

    test('returns missing when ruleId is empty', () async {
      final resolver = RuleResolver(
        customRuleRepository: customRuleRepo,
        assetProfiles: const [placeholderProfile],
      );

      final result = await resolver.resolve('   ');

      expect(result.isMissing, isTrue);
      final missing = result as RuleResolutionMissing;
      expect(missing.message, contains('Rule ID is empty'));
    });

    test('real project asset rules load successfully and resolve placeholder',
        () async {
      final loader = RuleProfileLoader();
      final loadResult = await loader.loadProfiles();

      // Ensure index.json and placeholder_example.json loaded without errors
      expect(loadResult.errors, isEmpty);
      expect(loadResult.profiles.length, 1);

      final loadedPlaceholder = loadResult.profiles.first;
      expect(loadedPlaceholder.id, 'placeholder_example');
      expect(loadedPlaceholder.label, 'Example profile (not a real state)');
      expect(loadedPlaceholder.requiredHours, 100);
      expect(loadedPlaceholder.requiredDays, 100);
      expect(loadedPlaceholder.coreSubjects, ['Math', 'Reading']);
      expect(loadedPlaceholder.sourceUrl, isNull);

      final resolver = RuleResolver(
        customRuleRepository: customRuleRepo,
        assetProfiles: loadResult.profiles,
      );

      final resolution = await resolver.resolve('placeholder_example');
      expect(resolution.isFound, isTrue);
      expect(resolution.profileOrNull, equals(loadedPlaceholder));
    });
  });
}
