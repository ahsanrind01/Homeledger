import '../domain/rule_profile.dart';
import '../domain/rule_resolution.dart';
import 'repositories/custom_rule_repository.dart';

/// Resolves child rule IDs (e.g. 'custom:1' or 'placeholder_example') to a [RuleProfile].
///
/// Designed to never crash: returns either [RuleResolutionFound] with the profile,
/// or [RuleResolutionMissing] with a clear diagnostic explanation.
class RuleResolver {
  final CustomRuleRepository customRuleRepository;
  final List<RuleProfile> assetProfiles;

  const RuleResolver({
    required this.customRuleRepository,
    required this.assetProfiles,
  });

  /// Resolves the given [ruleId].
  Future<RuleResolution> resolve(String ruleId) async {
    final trimmed = ruleId.trim();
    if (trimmed.isEmpty) {
      return RuleResolution.missing(ruleId, 'Rule ID is empty.');
    }

    // 1. Resolve custom rules from database
    if (trimmed.startsWith('custom:')) {
      final rawId = trimmed.substring('custom:'.length).trim();
      final id = int.tryParse(rawId);
      if (id == null) {
        return RuleResolution.missing(
          ruleId,
          'Custom rule identifier "$rawId" is not a valid integer ID.',
        );
      }

      try {
        final customRule = await customRuleRepository.getById(id);
        if (customRule == null) {
          return RuleResolution.missing(
            ruleId,
            'Custom rule #$id was not found in the database.',
          );
        }

        return RuleResolution.found(
          RuleProfile(
            id: ruleId,
            label: customRule.label,
            requiredHours: customRule.requiredHours,
            requiredDays: customRule.requiredDays,
            coreSubjects: const [],
            sourceUrl: null,
            lastChecked: null,
            isCustom: true,
            notes: null,
          ),
        );
      } catch (e) {
        return RuleResolution.missing(
          ruleId,
          'Failed to load custom rule #$id from database: $e',
        );
      }
    }

    // 2. Resolve standard asset profiles
    final profile = assetProfiles.where((p) => p.id == trimmed).firstOrNull;
    if (profile != null) {
      return RuleResolution.found(profile);
    }

    return RuleResolution.missing(
      ruleId,
      'Standard rule profile "$ruleId" was not found in registered rule profiles.',
    );
  }
}
