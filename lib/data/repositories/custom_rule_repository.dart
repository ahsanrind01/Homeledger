import 'package:drift/drift.dart';
import '../db/app_database.dart';

/// Repository for managing parent-defined custom rule profiles.
class CustomRuleRepository {
  final AppDatabase _db;

  const CustomRuleRepository(this._db);

  /// Inserts a new custom rule profile.
  /// Validates that at least one of [requiredHours] or [requiredDays] is specified.
  Future<int> add(CustomRulesCompanion rule) {
    _validateRule(rule.requiredHours, rule.requiredDays);
    return _db.into(_db.customRules).insert(rule);
  }

  /// Updates an existing custom rule profile.
  /// Validates that at least one of [requiredHours] or [requiredDays] is specified.
  Future<bool> update(CustomRule rule) {
    if (rule.requiredHours == null && rule.requiredDays == null) {
      throw ArgumentError(
        'At least one of requiredHours or requiredDays must be set.',
      );
    }
    return _db.update(_db.customRules).replace(rule);
  }

  /// Deletes a custom rule by its id.
  Future<int> delete(int id) {
    return (_db.delete(_db.customRules)..where((t) => t.id.equals(id))).go();
  }

  /// Fetches a custom rule by its id.
  Future<CustomRule?> getById(int id) {
    return (_db.select(_db.customRules)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Fetches all custom rules.
  Future<List<CustomRule>> getAll() {
    return _db.select(_db.customRules).get();
  }

  /// Continuously watches all custom rules.
  Stream<List<CustomRule>> watchAll() {
    return _db.select(_db.customRules).watch();
  }

  void _validateRule(Value<int?> requiredHours, Value<int?> requiredDays) {
    final hours = requiredHours.present ? requiredHours.value : null;
    final days = requiredDays.present ? requiredDays.value : null;

    if (hours == null && days == null) {
      throw ArgumentError(
        'At least one of requiredHours or requiredDays must be set.',
      );
    }
  }
}
