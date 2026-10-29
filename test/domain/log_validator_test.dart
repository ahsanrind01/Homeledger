import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/domain/log_validator.dart';

void main() {
  final today = DateTime(2026, 10, 19, 14, 30);
  final yesterday = DateTime(2026, 10, 18, 9, 0);
  final tomorrow = DateTime(2026, 10, 20, 8, 0);

  group('LogValidator', () {
    test('zero and negative minutes are blocked', () {
      final resZero = LogValidator.validate(
        minutesToAdd: 0,
        currentDayMinutes: 0,
        date: today,
        today: today,
      );
      expect(resZero.isBlocked, isTrue);
      expect(resZero.message, 'Minutes must be greater than 0');

      final resNegative = LogValidator.validate(
        minutesToAdd: -15,
        currentDayMinutes: 60,
        date: today,
        today: today,
      );
      expect(resNegative.isBlocked, isTrue);
      expect(resNegative.message, 'Minutes must be greater than 0');
    });

    test('future date is blocked, past date and today are allowed', () {
      final resFuture = LogValidator.validate(
        minutesToAdd: 30,
        currentDayMinutes: 0,
        date: tomorrow,
        today: today,
      );
      expect(resFuture.isBlocked, isTrue);
      expect(resFuture.message, 'Future dates are not allowed');

      final resToday = LogValidator.validate(
        minutesToAdd: 30,
        currentDayMinutes: 0,
        date: today,
        today: today,
      );
      expect(resToday.isAllowed, isTrue);

      final resPast = LogValidator.validate(
        minutesToAdd: 30,
        currentDayMinutes: 0,
        date: yesterday,
        today: today,
      );
      expect(resPast.isAllowed, isTrue);
    });

    test('note length max 200: 200 ok, 201 blocked', () {
      final note200 = 'a' * 200;
      final res200 = LogValidator.validate(
        minutesToAdd: 30,
        currentDayMinutes: 0,
        date: today,
        today: today,
        note: note200,
      );
      expect(res200.isAllowed, isTrue);

      final note201 = 'a' * 201;
      final res201 = LogValidator.validate(
        minutesToAdd: 30,
        currentDayMinutes: 0,
        date: today,
        today: today,
        note: note201,
      );
      expect(res201.isBlocked, isTrue);
      expect(res201.message, 'Note cannot exceed 200 characters');
    });

    test('10 h warning: up to 10 h is allowed, above 10 h triggers warning', () {
      // Exactly 10 hours (600 minutes) -> allowed without warning
      final res10h = LogValidator.validate(
        minutesToAdd: 60,
        currentDayMinutes: 9 * 60,
        date: today,
        today: today,
      );
      expect(res10h.isAllowed, isTrue);

      // 10 hours and 1 minute (601 minutes) -> triggers warning
      final resOver10h = LogValidator.validate(
        minutesToAdd: 61,
        currentDayMinutes: 9 * 60,
        date: today,
        today: today,
      );
      expect(resOver10h.isWarn, isTrue);
      expect(resOver10h.message, contains('Daily total will exceed 10 hours'));
    });

    test('23 h + 1 h is ok (with warning), 23 h + 61 min is blocked', () {
      const current23h = 23 * 60; // 1380 min

      // 23 h + 1 h = 24 h (1440 min) -> within 24h limit, not blocked!
      final res24h = LogValidator.validate(
        minutesToAdd: 60,
        currentDayMinutes: current23h,
        date: today,
        today: today,
      );
      expect(res24h.isBlocked, isFalse);
      expect(res24h.isWarn, isTrue);

      // 23 h + 61 min = 1441 min -> exceeds 24h limit, blocked!
      final resOver24h = LogValidator.validate(
        minutesToAdd: 61,
        currentDayMinutes: current23h,
        date: today,
        today: today,
      );
      expect(resOver24h.isBlocked, isTrue);
      expect(resOver24h.message, 'Daily total cannot exceed 24 hours');
    });
  });
}
