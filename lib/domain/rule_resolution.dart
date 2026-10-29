import 'rule_profile.dart';

/// Sealed class representing the result of resolving a rule ID.
///
/// Designed to never crash the caller: returns either [RuleResolutionFound]
/// with the valid profile, or [RuleResolutionMissing] with diagnostic details.
sealed class RuleResolution {
  const RuleResolution();

  /// True if the rule profile was successfully found.
  bool get isFound => this is RuleResolutionFound;

  /// True if the rule profile was missing or could not be found.
  bool get isMissing => this is RuleResolutionMissing;

  /// Returns the [RuleProfile] if found, or null if missing.
  RuleProfile? get profileOrNull => switch (this) {
        RuleResolutionFound(:final profile) => profile,
        RuleResolutionMissing() => null,
      };

  factory RuleResolution.found(RuleProfile profile) = RuleResolutionFound;
  factory RuleResolution.missing(String ruleId, [String message]) =
      RuleResolutionMissing;
}

/// Indicates the rule profile was found and resolved.
class RuleResolutionFound extends RuleResolution {
  final RuleProfile profile;

  const RuleResolutionFound(this.profile);

  @override
  String toString() => 'RuleResolutionFound(${profile.id})';
}

/// Indicates the rule profile could not be found.
class RuleResolutionMissing extends RuleResolution {
  final String ruleId;
  final String message;

  const RuleResolutionMissing(
    this.ruleId, [
    this.message = 'Rule profile not found',
  ]);

  @override
  String toString() => 'RuleResolutionMissing($ruleId: $message)';
}
