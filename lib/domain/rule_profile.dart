import 'package:flutter/foundation.dart';

/// Immutable model representing a homeschool requirement rule profile.
///
/// Rules define hours, days, and core subjects required by a state or
/// custom parent profile. All state rules are data (JSON), never hardcoded.
@immutable
class RuleProfile {
  /// Unique identifier (e.g. 'placeholder_example' or 'custom:1').
  final String id;

  /// Human-readable label (e.g. 'Example profile (not a real state)').
  final String label;

  /// Required learning hours, if mandated by the profile.
  final int? requiredHours;

  /// Required school days, if mandated by the profile.
  final int? requiredDays;

  /// List of core subject names associated with this requirement.
  final List<String> coreSubjects;

  /// Official education department source URL, or null for custom/placeholder profiles.
  final String? sourceUrl;

  /// Date this profile was verified against official sources (YYYY-MM-DD).
  final String? lastChecked;

  /// Whether this profile was created locally by a parent.
  final bool isCustom;

  /// Guidance notes or legal citations.
  final String? notes;

  const RuleProfile({
    required this.id,
    required this.label,
    this.requiredHours,
    this.requiredDays,
    this.coreSubjects = const [],
    this.sourceUrl,
    this.lastChecked,
    this.isCustom = false,
    this.notes,
  })  : assert(
          id.length > 0,
          'RuleProfile id must not be empty.',
        ),
        assert(
          label.length > 0,
          'RuleProfile label must not be empty.',
        ),
        assert(
          (requiredHours != null && requiredHours > 0) ||
              (requiredDays != null && requiredDays > 0),
          'At least one of requiredHours or requiredDays must be set and positive.',
        ),
        assert(
          requiredHours == null || requiredHours >= 0,
          'requiredHours cannot be negative.',
        ),
        assert(
          requiredDays == null || requiredDays >= 0,
          'requiredDays cannot be negative.',
        );

  /// Deserializes a valid JSON map into a [RuleProfile].
  factory RuleProfile.fromJson(
    Map<String, dynamic> json, {
    bool isCustom = false,
  }) {
    return RuleProfile(
      id: json['id'] as String,
      label: json['label'] as String,
      requiredHours: json['requiredHours'] as int?,
      requiredDays: json['requiredDays'] as int?,
      coreSubjects: (json['coreSubjects'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      sourceUrl: json['sourceUrl'] as String?,
      lastChecked: json['lastChecked'] as String?,
      isCustom: isCustom || (json['isCustom'] as bool? ?? false),
      notes: json['notes'] as String?,
    );
  }

  /// Converts this [RuleProfile] to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'requiredHours': requiredHours,
      'requiredDays': requiredDays,
      'coreSubjects': coreSubjects,
      'sourceUrl': sourceUrl,
      'lastChecked': lastChecked,
      'isCustom': isCustom,
      'notes': notes,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RuleProfile &&
        other.id == id &&
        other.label == label &&
        other.requiredHours == requiredHours &&
        other.requiredDays == requiredDays &&
        listEquals(other.coreSubjects, coreSubjects) &&
        other.sourceUrl == sourceUrl &&
        other.lastChecked == lastChecked &&
        other.isCustom == isCustom &&
        other.notes == notes;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      label,
      requiredHours,
      requiredDays,
      Object.hashAll(coreSubjects),
      sourceUrl,
      lastChecked,
      isCustom,
      notes,
    );
  }

  @override
  String toString() {
    return 'RuleProfile(id: $id, label: $label, hours: $requiredHours, days: $requiredDays, custom: $isCustom)';
  }
}
