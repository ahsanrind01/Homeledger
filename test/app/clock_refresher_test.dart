import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/app/clock_refresher.dart';
import 'package:homeledger/data/db/app_database.dart';
import 'package:homeledger/data/providers.dart';
import 'package:homeledger/data/repositories/child_repository.dart';
import 'package:homeledger/data/repositories/log_repository.dart';
import 'package:homeledger/data/repositories/subject_repository.dart';
import 'package:homeledger/domain/rule_profile.dart';
import 'package:homeledger/domain/rule_resolution.dart';
import 'package:homeledger/features/home/home_screen.dart';
import 'package:homeledger/features/log/log_screen.dart';

class MutableHolder<T> {
  T value;
  MutableHolder(this.value);
}

void main() {
  const kTestRule = RuleProfile(
    id: 'placeholder_example',
    label: 'Standard',
    requiredHours: 900,
    requiredDays: 180,
    coreSubjects: ['Math'],
    isCustom: false,
  );

  group('timeUntilNextMidnight pure function', () {
    test('23:59:59 -> 1 s + 1 s margin (2 seconds total)', () {
      final now = DateTime(2026, 10, 20, 23, 59, 59);
      final duration = timeUntilNextMidnight(now);
      expect(duration, const Duration(seconds: 2));
    });

    test('00:00:00 -> 24 h + 1 s', () {
      final now = DateTime(2026, 10, 20, 0, 0, 0);
      final duration = timeUntilNextMidnight(now);
      expect(duration, const Duration(hours: 24, seconds: 1));
    });

    test('Mid-day calculation lands exactly 1 second after local midnight', () {
      final now = DateTime(2026, 10, 20, 14, 30, 0);
      final duration = timeUntilNextMidnight(now);
      final target = now.add(duration);
      expect(target.year, 2026);
      expect(target.month, 10);
      expect(target.day, 21);
      expect(target.hour, 0);
      expect(target.minute, 0);
      expect(target.second, 1);
    });

    test('Daylight-saving day transition lands on the next local midnight', () {
      // Nov 1, 2026 is standard US DST fall-back day
      final dstDate = DateTime(2026, 11, 1, 10, 0, 0);
      final duration = timeUntilNextMidnight(dstDate);
      final target = dstDate.add(duration);
      expect(target.year, 2026);
      expect(target.month, 11);
      expect(target.day, 2);
      expect(target.hour, 0);
      expect(target.minute, 0);
      expect(target.second, 1);
    });
  });

  group('ClockRefresher widget tests', () {
    testWidgets(
        'AppLifecycleState.resumed date change invalidates clockProvider, updating Home Today to 0 min while preserving This week',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final childRepo = ChildRepository(db);
      final subjectRepo = SubjectRepository(db);
      final logRepo = LogRepository(db);

      final childId = await childRepo.add(
        ChildrenCompanion.insert(
          name: 'Maya',
          ruleId: 'placeholder_example',
          schoolYearStart: '2026-08-01',
          schoolYearEnd: '2027-05-31',
          createdAt: 1000,
        ),
      );

      final subjectId = await subjectRepo.add(
        SubjectsCompanion.insert(name: 'Math'),
      );

      // Tuesday, Oct 20, 2026
      final fakeNow = MutableHolder(DateTime(2026, 10, 20, 10, 0));

      // Log 30 min on Tuesday Oct 20
      await logRepo.add(
        LogEntriesCompanion.insert(
          childId: childId,
          subjectId: subjectId,
          day: '2026-10-20',
          minutes: 30,
          createdAt: fakeNow.value.millisecondsSinceEpoch,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            clockProvider.overrideWith((ref) => fakeNow.value),
            resolveRuleProvider('placeholder_example').overrideWith(
              (ref) => Future.value(const RuleResolutionFound(kTestRule)),
            ),
          ],
          child: ClockRefresher(
            now: () => fakeNow.value,
            child: const MaterialApp(
              home: HomeScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // On day D (Oct 20): Today is 30 min, This week is 30 min
      expect(find.text('30 min'), findsWidgets);

      // Advance to day D+1: Wednesday, Oct 21, 2026 (same Monday-Sunday week)
      fakeNow.value = DateTime(2026, 10, 21, 9, 0);

      // Trigger app resumed lifecycle event
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      // On day D+1: Today should be 0 min, and This week still includes the 30 min
      expect(find.byKey(const ValueKey('home_today_total_text')), findsOneWidget);
      expect(find.byKey(const ValueKey('home_week_total_text')), findsOneWidget);
      expect(find.text('30 min'), findsWidgets);

      // Open LogScreen from Home
      final logTimeButton = find.widgetWithText(FilledButton, 'Log time');
      await tester.ensureVisible(logTimeButton);
      await tester.tap(logTimeButton);
      await tester.pumpAndSettle();

      // Check date label contains new date D+1 and '(Today)'
      expect(find.text('2026-10-21 (Today)'), findsOneWidget);

      // Clean up timers
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });

    testWidgets('On day D+1 the log screen accepts a log for D+1 without future date error',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final childRepo = ChildRepository(db);
      final subjectRepo = SubjectRepository(db);

      final childId = await childRepo.add(
        ChildrenCompanion.insert(
          name: 'Maya',
          ruleId: 'placeholder_example',
          schoolYearStart: '2026-08-01',
          schoolYearEnd: '2027-05-31',
          createdAt: 1000,
        ),
      );

      await subjectRepo.add(
        SubjectsCompanion.insert(name: 'Math'),
      );

      // Advance clock to Day D+1: Oct 21, 2026
      final fakeNow = MutableHolder(DateTime(2026, 10, 21, 9, 0));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            clockProvider.overrideWith((ref) => fakeNow.value),
            resolveRuleProvider('placeholder_example').overrideWith(
              (ref) => Future.value(const RuleResolutionFound(kTestRule)),
            ),
          ],
          child: ClockRefresher(
            child: MaterialApp(
              home: LogScreen(childId: childId),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap +30 min for Day D+1 and Add lesson
      final plus30Button = find.text('+30 min');
      await tester.ensureVisible(plus30Button);
      await tester.tap(plus30Button);
      await tester.pumpAndSettle();
      final addLessonButton = find.widgetWithText(FilledButton, 'Add lesson');
      await tester.ensureVisible(addLessonButton);
      await tester.tap(addLessonButton);
      await tester.pumpAndSettle();

      // Verify no future date blocking snackbar appears
      expect(find.text('Future dates are not allowed'), findsNothing);
      expect(find.textContaining('Added 30 min'), findsOneWidget);

      // Clean up timers
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  });
}
