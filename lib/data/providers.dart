import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/formatters.dart';
import '../domain/progress_calculator.dart';
import '../domain/rule_profile.dart';
import '../domain/rule_resolution.dart';
import 'db/app_database.dart';
import '../services/child_deletion_service.dart';
import '../services/sample_capture_service.dart';
import '../services/sample_storage_service.dart';
import 'repositories/child_repository.dart';
import 'repositories/custom_rule_repository.dart';
import 'repositories/entitlement_repository.dart';
import 'repositories/log_repository.dart';
import 'repositories/sample_repository.dart';
import 'repositories/settings_repository.dart';
import 'repositories/subject_repository.dart';
import 'rule_profile_loader.dart';
import 'rule_resolver.dart';
import '../features/export/export_service.dart';
import '../features/backup/backup_clients.dart';
import '../features/backup/backup_service.dart';
import '../domain/entitlement.dart';
import '../domain/feature_policy.dart';
import '../domain/core_subjects.dart';
import '../services/entitlement_service.dart';
import '../core/purchases_config.dart';
import '../services/revenuecat_entitlement_service.dart';

/// Provider for the singleton AppDatabase instance.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// Provider for ChildRepository.
final childRepositoryProvider = Provider<ChildRepository>((ref) {
  return ChildRepository(ref.watch(appDatabaseProvider));
});

/// Provider for SubjectRepository.
final subjectRepositoryProvider = Provider<SubjectRepository>((ref) {
  return SubjectRepository(ref.watch(appDatabaseProvider));
});

/// Provider for LogRepository.
final logRepositoryProvider = Provider<LogRepository>((ref) {
  return LogRepository(ref.watch(appDatabaseProvider));
});

/// Provider for SampleRepository.
final sampleRepositoryProvider = Provider<SampleRepository>((ref) {
  return SampleRepository(ref.watch(appDatabaseProvider));
});

/// Provider for SampleStorageService.
final sampleStorageServiceProvider = Provider<SampleStorageService>((ref) {
  return SampleStorageService(
    sampleRepository: ref.watch(sampleRepositoryProvider),
    clock: () => ref.read(clockProvider),
  );
});


/// Provider for ChildDeletionService.
final childDeletionServiceProvider = Provider<ChildDeletionService>((ref) {
  return ChildDeletionService(
    childRepository: ref.watch(childRepositoryProvider),
    sampleStorageService: ref.watch(sampleStorageServiceProvider),
  );
});

/// Provider for SampleCaptureService.
final sampleCaptureServiceProvider = Provider<SampleCaptureService>((ref) {
  return SampleCaptureService();
});

/// Provider for CustomRuleRepository.
final customRuleRepositoryProvider = Provider<CustomRuleRepository>((ref) {
  return CustomRuleRepository(ref.watch(appDatabaseProvider));
});

/// Provider for EntitlementRepository.
final entitlementRepositoryProvider = Provider<EntitlementRepository>((ref) {
  return EntitlementRepository(ref.watch(appDatabaseProvider));
});

/// Provider for SettingsRepository.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(appDatabaseProvider));
});

/// StreamProvider watching all subjects ordered by sortOrder.
final subjectsStreamProvider = StreamProvider<List<Subject>>((ref) {
  return ref.watch(subjectRepositoryProvider).watchAll();
});

/// StreamProvider watching all children ordered by creation time.
final childrenStreamProvider = StreamProvider<List<Child>>((ref) {
  return ref.watch(childRepositoryProvider).watchAll();
});


/// Provider for RuleProfileLoader.
final ruleProfileLoaderProvider = Provider<RuleProfileLoader>((ref) {
  return RuleProfileLoader();
});

/// Provider for loading the rule profiles and error logs from assets.
final ruleProfilesLoadResultProvider =
    FutureProvider<ProfileLoadResult>((ref) async {
  final loader = ref.watch(ruleProfileLoaderProvider);
  return loader.loadProfiles();
});

/// Provider for the list of loaded valid asset RuleProfiles.
final ruleProfilesProvider = FutureProvider<List<RuleProfile>>((ref) async {
  final result = await ref.watch(ruleProfilesLoadResultProvider.future);
  return result.profiles;
});

/// Provider for RuleResolver, initialized with the custom rule repository and loaded asset profiles.
final ruleResolverProvider = FutureProvider<RuleResolver>((ref) async {
  final customRuleRepo = ref.watch(customRuleRepositoryProvider);
  final profiles = await ref.watch(ruleProfilesProvider.future);
  return RuleResolver(
    customRuleRepository: customRuleRepo,
    assetProfiles: profiles,
  );
});

/// Family provider to easily resolve a ruleId to a RuleResolution.
final resolveRuleProvider =
    FutureProvider.family<RuleResolution, String>((ref, ruleId) async {
  final resolver = await ref.watch(ruleResolverProvider.future);
  return resolver.resolve(ruleId);
});

/// Provider for the system clock date and time.
/// Injecting this allows tests to fix 'today' deterministically.
final clockProvider = Provider<DateTime>((ref) {
  return DateTime.now();
});

/// Notifier holding the currently selected child ID on the dashboard.
class SelectedChildIdNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void select(int? id) => state = id;
}

/// Provider holding the currently selected child ID on the dashboard.
final selectedChildIdProvider =
    NotifierProvider<SelectedChildIdNotifier, int?>(SelectedChildIdNotifier.new);

/// StreamProvider watching today's total logged minutes for a specific child.
final todayMinutesProvider = StreamProvider.family<int, int>((ref, childId) {
  final logRepo = ref.watch(logRepositoryProvider);
  final today = ref.watch(clockProvider);
  final todayStr = formatIsoDate(today);
  return logRepo.watchTotalMinutes(childId, todayStr, todayStr);
});

/// StreamProvider watching this week's total logged minutes for a specific child (Monday to today).
final weekMinutesProvider = StreamProvider.family<int, int>((ref, childId) {
  final logRepo = ref.watch(logRepositoryProvider);
  final today = ref.watch(clockProvider);
  final monday = DateTime(today.year, today.month, today.day)
      .subtract(Duration(days: today.weekday - 1));
  final fromStr = formatIsoDate(monday);
  final toStr = formatIsoDate(today);
  return logRepo.watchTotalMinutes(childId, fromStr, toStr);
});

/// State data class holding all calculated progress and subject details for a child.
class ChildProgressState {
  final Child child;
  final RuleResolution ruleResolution;
  final ProgressResult? progress;
  final Map<Subject, int> minutesBySubject;

  const ChildProgressState({
    required this.child,
    required this.ruleResolution,
    this.progress,
    this.minutesBySubject = const {},
  });

  bool get isRuleMissing => ruleResolution is RuleResolutionMissing;
}

/// StreamProvider family that calculates real-time progress for a child using ProgressCalculator.
/// Updates automatically whenever log entries for this child are added, updated, or deleted.
final childProgressProvider =
    StreamProvider.family<ChildProgressState?, int>((ref, childId) async* {
  final childRepo = ref.watch(childRepositoryProvider);
  final logRepo = ref.watch(logRepositoryProvider);
  final subjectRepo = ref.watch(subjectRepositoryProvider);
  final clock = ref.watch(clockProvider);
  ref.watch(childrenStreamProvider);
  ref.watch(subjectsStreamProvider);

  await for (final _ in logRepo.watchForChild(childId)) {
    if (!ref.mounted) break;
    final child = await childRepo.getById(childId);
    if (!ref.mounted) break;
    if (child == null) {
      yield null;
      continue;
    }

    final resolution =
        await ref.read(resolveRuleProvider(child.ruleId).future);
    if (!ref.mounted) break;
    final subjects = await subjectRepo.getAll();
    final subjectMap = {for (final s in subjects) s.id: s};
    final coreSubjects = coreSubjectsFor(subjects);
    final coreSubjectIds = {for (final s in coreSubjects) s.id};

    final minutesBySubjectId = await logRepo.minutesBySubject(
      childId,
      child.schoolYearStart,
      child.schoolYearEnd,
    );

    final minutesBySubject = <Subject, int>{};
    final coreMinutesByName = <String, int>{};

    for (final entry in minutesBySubjectId.entries) {
      final subject = subjectMap[entry.key];
      if (subject != null) {
        minutesBySubject[subject] = entry.value;
        if (coreSubjectIds.contains(subject.id)) {
          coreMinutesByName[subject.name] = entry.value;
        }
      }
    }

    if (resolution is RuleResolutionFound) {
      final profile = resolution.profile;
      final totalMinutes = await logRepo.totalMinutes(
        childId,
        child.schoolYearStart,
        child.schoolYearEnd,
      );
      final daysLogged = await logRepo.distinctDaysLogged(
        childId,
        child.schoolYearStart,
        child.schoolYearEnd,
      );

      DateTime start;
      DateTime end;
      try {
        start = DateTime.parse(child.schoolYearStart);
        end = DateTime.parse(child.schoolYearEnd);
      } catch (_) {
        start = clock;
        end = clock.add(const Duration(days: 180));
      }

      final progress = ProgressCalculator.calculate(
        requiredMinutes: profile.requiredHours != null
            ? profile.requiredHours! * 60
            : null,
        requiredDays: profile.requiredDays,
        minutesDone: totalMinutes,
        daysLogged: daysLogged,
        coreMinutesBySubject: coreMinutesByName,
        coreSubjects: profile.coreSubjects,
        schoolYearStart: start,
        schoolYearEnd: end,
        today: clock,
      );

      yield ChildProgressState(
        child: child,
        ruleResolution: resolution,
        progress: progress,
        minutesBySubject: minutesBySubject,
      );
    } else {
      yield ChildProgressState(
        child: child,
        ruleResolution: resolution,
        progress: null,
        minutesBySubject: minutesBySubject,
      );
    }
  }
});

/// StreamProvider watching the optional parent name from settings.
final parentNameStreamProvider = StreamProvider<String?>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.watchParentName();
});

/// Provider for PdfShareClient (defaulting to SharePlusPdfShareClient).
final pdfShareClientProvider = Provider<PdfShareClient>((ref) {
  return SharePlusPdfShareClient();
});

/// Provider for ExportService.
final exportServiceProvider = FutureProvider<ExportService>((ref) async {
  final resolver = await ref.watch(ruleResolverProvider.future);
  return ExportService(
    childRepo: ref.watch(childRepositoryProvider),
    ruleResolver: resolver,
    subjectRepo: ref.watch(subjectRepositoryProvider),
    logRepo: ref.watch(logRepositoryProvider),
    sampleRepo: ref.watch(sampleRepositoryProvider),
    settingsRepo: ref.watch(settingsRepositoryProvider),
    sampleStorageService: ref.watch(sampleStorageServiceProvider),
    shareClient: ref.watch(pdfShareClientProvider),
    clock: () => ref.read(clockProvider),
  );
});

/// Provider for BackupShareClient (defaulting to SharePlusBackupShareClient).
final backupShareClientProvider = Provider<BackupShareClient>((ref) {
  return SharePlusBackupShareClient();
});

/// Provider for FilePickerClient (defaulting to SystemFilePickerClient).
final filePickerClientProvider = Provider<FilePickerClient>((ref) {
  return SystemFilePickerClient();
});

/// Provider for BackupService.
final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    db: ref.watch(appDatabaseProvider),
    childRepo: ref.watch(childRepositoryProvider),
    logRepo: ref.watch(logRepositoryProvider),
    sampleRepo: ref.watch(sampleRepositoryProvider),
    settingsRepo: ref.watch(settingsRepositoryProvider),
    shareClient: ref.watch(backupShareClientProvider),
    filePickerClient: ref.watch(filePickerClientProvider),
    clock: () => ref.read(clockProvider),
  );
});

/// StreamProvider watching the date of the last successful backup.
final lastBackupDateStreamProvider = StreamProvider<String?>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.watchLastBackupDate();
});

/// Provider indicating whether the gentle 30-day backup reminder should show on Home.
final shouldShowBackupReminderProvider = FutureProvider<bool>((ref) async {
  final children = await ref.watch(childRepositoryProvider).getAll();
  if (children.isEmpty) return false;

  final now = ref.watch(clockProvider);
  final settingsRepo = ref.watch(settingsRepositoryProvider);

  // Check if reminder was recently dismissed (within last 30 days)
  final dismissedDateStr = await settingsRepo.getDismissedBackupReminderDate();
  if (dismissedDateStr != null) {
    final dismissed = DateTime.tryParse(dismissedDateStr);
    if (dismissed != null && now.difference(dismissed).inDays < 30) {
      return false;
    }
  }

  // Check last backup date
  final lastBackupStr = await settingsRepo.getLastBackupDate();
  if (lastBackupStr != null) {
    final lastBackup = DateTime.tryParse(lastBackupStr);
    if (lastBackup != null) {
      return now.difference(lastBackup).inDays >= 30;
    }
  }

  // If no backup was ever made, check if the earliest child is older than 30 days
  final earliestCreatedAt = children.map((c) => c.createdAt).reduce((a, b) => a < b ? a : b);
  final createdDate = DateTime.fromMillisecondsSinceEpoch(earliestCreatedAt);
  return now.difference(createdDate).inDays >= 30;
});

/// Provider for FakeEntitlementService.
final fakeEntitlementServiceProvider = Provider<FakeEntitlementService>((ref) {
  return FakeEntitlementService(
    ref.watch(entitlementRepositoryProvider),
    clock: () => ref.read(clockProvider),
  );
});

/// Provider for RevenueCatEntitlementService.
final revenueCatEntitlementServiceProvider =
    Provider<RevenueCatEntitlementService>((ref) {
  final service = RevenueCatEntitlementService(
    ref.watch(entitlementRepositoryProvider),
    clock: () => ref.read(clockProvider),
  );
  // Asynchronously trigger initialization
  service.initialize();
  return service;
});

/// Provider exposing EntitlementService interface.
/// In production with RevenueCat keys configured, this returns [RevenueCatEntitlementService].
/// Otherwise, it falls back to [FakeEntitlementService] for tests and local development.
final entitlementServiceProvider = Provider<EntitlementService>((ref) {
  if (PurchasesConfig.isPurchasesConfigured) {
    return ref.watch(revenueCatEntitlementServiceProvider);
  }
  return ref.watch(fakeEntitlementServiceProvider);
});

/// StreamProvider watching device entitlement changes.
final entitlementStateStreamProvider = StreamProvider<EntitlementState>((ref) {
  final service = ref.watch(entitlementServiceProvider);
  return service.changes;
});

/// Provider family resolving [FeatureAccess] for any [Feature].
///
/// NOTE: Every screen and widget checking feature access MUST use this provider
/// (or call [canUse] directly) to guarantee that all gating rules are centralized.
final featureAccessProvider =
    Provider.family<FeatureAccess, Feature>((ref, feature) {
  final entitlementAsync = ref.watch(entitlementStateStreamProvider);
  final entitlement = entitlementAsync.value ?? const EntitlementState.free();
  final now = ref.watch(clockProvider);
  return canUse(feature, entitlement, now);
});

/// StreamProvider watching recent log entries for a child (ordered newest first).
final childRecentLogsStreamProvider =
    StreamProvider.family<List<LogEntry>, int>((ref, childId) {
  return ref.watch(logRepositoryProvider).watchForChild(childId);
});

