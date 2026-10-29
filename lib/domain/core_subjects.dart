import '../data/db/app_database.dart';

/// Pure domain helper for determining which subjects count as core curriculum.
///
/// Disclaimers: Records tool, not legal advice.

/// Returns the subset of [all] subjects that count as core.
List<Subject> coreSubjectsFor(List<Subject> all) {
  return all.where(isCoreSubject).toList();
}

/// Evaluates whether an individual [Subject] counts as core.
bool isCoreSubject(Subject subject) {
  return subject.isCore;
}

/// Formats core subject status for display ('Yes' / 'No').
String formatCoreStatus(bool isCore) {
  return isCore ? 'Yes' : 'No';
}
