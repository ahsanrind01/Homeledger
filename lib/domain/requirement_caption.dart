/// Computes the honest requirement caption for the Progress screen and PDF portfolio.
///
/// Discloses whether a target is an example placeholder or parent-created custom goal,
/// preventing parents from mistaking them for official state legal mandates.
String? getRequirementCaption({
  required String ruleId,
  bool isCustom = false,
}) {
  final trimmed = ruleId.trim();
  if (trimmed == 'placeholder_example') {
    return "Example target only. It is not your state's rule. Set your own in Edit child.";
  }
  if (isCustom || trimmed.startsWith('custom:')) {
    return "Your own target. Check your state's rules.";
  }
  return null;
}
