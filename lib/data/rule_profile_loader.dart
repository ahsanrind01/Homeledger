import 'dart:convert';
import 'package:flutter/services.dart';
import '../domain/rule_profile.dart';

/// Result of attempting to load rule profiles from assets.
class ProfileLoadResult {
  /// The list of successfully validated and parsed rule profiles.
  final List<RuleProfile> profiles;

  /// Human-readable error messages for any profiles that failed validation or parsing.
  final List<String> errors;

  const ProfileLoadResult({
    required this.profiles,
    required this.errors,
  });
}

/// Loads and validates rule profiles from application assets.
///
/// Designed to never crash the application on malformed JSON or invalid data:
/// bad profiles are skipped and recorded in [ProfileLoadResult.errors].
class RuleProfileLoader {
  final AssetBundle _assetBundle;

  RuleProfileLoader({AssetBundle? assetBundle})
      : _assetBundle = assetBundle ?? rootBundle;

  /// Loads the profiles listed in [indexPath] (default 'assets/rules/index.json').
  Future<ProfileLoadResult> loadProfiles({
    String indexPath = 'assets/rules/index.json',
  }) async {
    final validProfiles = <RuleProfile>[];
    final errors = <String>[];
    final loadedIds = <String>{};

    String indexRaw;
    try {
      indexRaw = await _assetBundle.loadString(indexPath);
    } catch (e) {
      errors.add('Failed to read index file "$indexPath": $e');
      return ProfileLoadResult(profiles: validProfiles, errors: errors);
    }

    dynamic indexJson;
    try {
      indexJson = jsonDecode(indexRaw);
    } catch (e) {
      errors.add('Index file "$indexPath" is not valid JSON: $e');
      return ProfileLoadResult(profiles: validProfiles, errors: errors);
    }

    if (indexJson is! List) {
      errors.add('Index file "$indexPath" must be a JSON array of filenames');
      return ProfileLoadResult(profiles: validProfiles, errors: errors);
    }

    for (final item in indexJson) {
      if (item is! String || item.trim().isEmpty) {
        errors.add('Index file contains an invalid non-string filename entry');
        continue;
      }

      final fileName = item.trim();
      final fullPath = fileName.startsWith('assets/rules/')
          ? fileName
          : 'assets/rules/$fileName';

      String profileRaw;
      try {
        profileRaw = await _assetBundle.loadString(fullPath);
      } catch (e) {
        errors.add('Failed to load profile asset "$fullPath": $e');
        continue;
      }

      dynamic profileJson;
      try {
        profileJson = jsonDecode(profileRaw);
      } catch (e) {
        errors.add('Profile "$fullPath" is not valid JSON: $e');
        continue;
      }

      if (profileJson is! Map<String, dynamic>) {
        errors.add('Profile "$fullPath" must be a JSON object');
        continue;
      }

      final validationError = validateProfileMap(
        profileJson,
        existingIds: loadedIds,
      );

      if (validationError != null) {
        errors.add('Invalid profile in "$fullPath": $validationError');
        continue;
      }

      try {
        final profile = RuleProfile.fromJson(profileJson, isCustom: false);
        validProfiles.add(profile);
        loadedIds.add(profile.id);
      } catch (e) {
        errors.add('Failed to instantiate profile from "$fullPath": $e');
      }
    }

    return ProfileLoadResult(profiles: validProfiles, errors: errors);
  }

  /// Validates a raw JSON map against all rule profile requirements.
  ///
  /// Returns null if valid, or a descriptive error message if invalid.
  static String? validateProfileMap(
    Map<String, dynamic> json, {
    Set<String>? existingIds,
  }) {
    // 1. Validate ID: non-empty string and unique
    final id = json['id'];
    if (id == null || id is! String || id.trim().isEmpty) {
      return 'Profile id must be a non-empty string';
    }
    if (existingIds != null && existingIds.contains(id.trim())) {
      return 'Duplicate profile id: "$id"';
    }

    // 2. Validate Label: non-empty string
    final label = json['label'];
    if (label == null || label is! String || label.trim().isEmpty) {
      return 'Profile label must be a non-empty string for profile "$id"';
    }

    // 3. Validate requiredHours
    final hours = json['requiredHours'];
    if (hours != null) {
      if (hours is! int) {
        return 'requiredHours must be an integer or null for profile "$id"';
      }
      if (hours < 0) {
        return 'requiredHours cannot be negative for profile "$id"';
      }
    }

    // 4. Validate requiredDays
    final days = json['requiredDays'];
    if (days != null) {
      if (days is! int) {
        return 'requiredDays must be an integer or null for profile "$id"';
      }
      if (days < 0) {
        return 'requiredDays cannot be negative for profile "$id"';
      }
    }

    // 5. At least one of hours or days must be positive (> 0)
    final hasPositiveHours = hours is int && hours > 0;
    final hasPositiveDays = days is int && days > 0;
    if (!hasPositiveHours && !hasPositiveDays) {
      return 'Profile "$id" must have at least one positive requirement (requiredHours > 0 or requiredDays > 0)';
    }

    // 6. Validate lastChecked: if present, must be a real calendar date YYYY-MM-DD
    final lastChecked = json['lastChecked'];
    if (lastChecked != null) {
      if (lastChecked is! String || !isValidDateString(lastChecked)) {
        return 'lastChecked "$lastChecked" is not a valid date (must be YYYY-MM-DD)';
      }
    }

    // 7. Validate coreSubjects: if present, must be a List
    final coreSubjects = json['coreSubjects'];
    if (coreSubjects != null && coreSubjects is! List) {
      return 'coreSubjects must be a list of subject name strings for profile "$id"';
    }

    return null;
  }

  /// Verifies that a string represents a real, valid calendar date in YYYY-MM-DD format.
  /// Rejects malformed strings as well as invalid dates like 2026-02-30 or 2026-13-45.
  static bool isValidDateString(String dateStr) {
    final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!regex.hasMatch(dateStr)) return false;

    final parts = dateStr.split('-');
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);

    if (year == null || month == null || day == null) return false;
    if (month < 1 || month > 12) return false;
    if (day < 1 || day > 31) return false;

    final parsed = DateTime.tryParse(dateStr);
    if (parsed == null) return false;

    // Verify calendar component identity to catch overflow days (e.g. Feb 30 -> Mar 2)
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return false;
    }

    return true;
  }
}
