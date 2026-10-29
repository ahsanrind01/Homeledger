import 'package:flutter/material.dart';

/// Cheerful, child-friendly visual styling and iconography for subjects,
/// avatars, and progress diagrams in Homeledger.
class KidsVisuals {
  const KidsVisuals._();

  /// Curated joyful color palettes for subjects
  static const List<Color> pastelRainbow = [
    Color(0xFF4F46E5), // Indigo
    Color(0xFFE11D48), // Rose
    Color(0xFF059669), // Emerald
    Color(0xFFD97706), // Amber
    Color(0xFF7C3AED), // Purple
    Color(0xFF0284C7), // Sky Blue
    Color(0xFFDB2777), // Pink
    Color(0xFF0D9488), // Teal
  ];

  /// Cheerful avatar icon & gradient definitions for children
  static const List<(IconData, Color, Color)> childAvatarStyles = [
    (Icons.face_rounded, Color(0xFFF97316), Color(0xFFFBBF24)), // Sunny Orange
    (Icons.pets_rounded, Color(0xFF10B981), Color(0xFF34D399)), // Forest Mint
    (Icons.rocket_launch_rounded, Color(0xFF3B82F6), Color(0xFF60A5FA)), // Sky Rocket
    (Icons.auto_awesome_rounded, Color(0xFF8B5CF6), Color(0xFFA78BFA)), // Magic Purple
    (Icons.palette_rounded, Color(0xFFEC4899), Color(0xFFF472B6)), // Coral Pink
    (Icons.sports_soccer_rounded, Color(0xFF06B6D4), Color(0xFF22D3EE)), // Cyan Energy
    (Icons.nature_people_rounded, Color(0xFF14B8A6), Color(0xFF2DD4BF)), // Teal Nature
  ];

  /// Returns styling for a child based on their ID
  static (IconData, Color, Color) getAvatarStyle(int childId) {
    final index = (childId.abs()) % childAvatarStyles.length;
    return childAvatarStyles[index];
  }

  /// Maps a subject name to a distinctive, cheerful icon, color, and background.
  static SubjectVisual getSubjectVisual(String name, {bool isCore = false}) {
    final lower = name.toLowerCase().trim();

    if (lower.contains('math') || lower.contains('algebra') || lower.contains('geometry') || lower.contains('calculus') || lower.contains('arithmetic')) {
      return const SubjectVisual(
        icon: Icons.calculate_rounded,
        color: Color(0xFF4F46E5),
        bgColor: Color(0xFFEEF2FF),
        badgeColor: Color(0xFFC7D2FE),
        label: 'Math',
      );
    }
    if (lower.contains('read') || lower.contains('english') || lower.contains('literature') || lower.contains('language') || lower.contains('phonics') || lower.contains('writing') || lower.contains('grammar') || lower.contains('spelling')) {
      return const SubjectVisual(
        icon: Icons.auto_stories_rounded,
        color: Color(0xFFE11D48),
        bgColor: Color(0xFFFFE4E6),
        badgeColor: Color(0xFFFECDD3),
        label: 'Language',
      );
    }
    if (lower.contains('science') || lower.contains('biology') || lower.contains('chemistry') || lower.contains('physics') || lower.contains('nature') || lower.contains('earth') || lower.contains('space') || lower.contains('astronomy')) {
      return const SubjectVisual(
        icon: Icons.biotech_rounded,
        color: Color(0xFF059669),
        bgColor: Color(0xFFD1FAE5),
        badgeColor: Color(0xFFA7F3D0),
        label: 'Science',
      );
    }
    if (lower.contains('history') || lower.contains('social') || lower.contains('geography') || lower.contains('civics') || lower.contains('government') || lower.contains('world')) {
      return const SubjectVisual(
        icon: Icons.public_rounded,
        color: Color(0xFFD97706),
        bgColor: Color(0xFFFEF3C7),
        badgeColor: Color(0xFFFDE68A),
        label: 'Social Studies',
      );
    }
    if (lower.contains('art') || lower.contains('craft') || lower.contains('draw') || lower.contains('paint')) {
      return const SubjectVisual(
        icon: Icons.palette_rounded,
        color: Color(0xFF7C3AED),
        bgColor: Color(0xFFEDE9FE),
        badgeColor: Color(0xFFDDD6FE),
        label: 'Art',
      );
    }
    if (lower.contains('music') || lower.contains('piano') || lower.contains('guitar') || lower.contains('sing') || lower.contains('instrument')) {
      return const SubjectVisual(
        icon: Icons.music_note_rounded,
        color: Color(0xFFDB2777),
        bgColor: Color(0xFFFCE7F3),
        badgeColor: Color(0xFFFBCFE8),
        label: 'Music',
      );
    }
    if (lower.contains('pe') || lower.contains('phys') || lower.contains('gym') || lower.contains('sport') || lower.contains('swim') || lower.contains('exercise') || lower.contains('fitness')) {
      return const SubjectVisual(
        icon: Icons.sports_soccer_rounded,
        color: Color(0xFF0284C7),
        bgColor: Color(0xFFE0F2FE),
        badgeColor: Color(0xFFBAE6FD),
        label: 'PE',
      );
    }
    if (lower.contains('bible') || lower.contains('relig') || lower.contains('faith') || lower.contains('moral') || lower.contains('character')) {
      return const SubjectVisual(
        icon: Icons.favorite_rounded,
        color: Color(0xFF0D9488),
        bgColor: Color(0xFFCCFBF1),
        badgeColor: Color(0xFF99F6E4),
        label: 'Faith',
      );
    }
    if (lower.contains('spanish') || lower.contains('french') || lower.contains('latin') || lower.contains('german') || lower.contains('chinese') || lower.contains('japanese')) {
      return const SubjectVisual(
        icon: Icons.translate_rounded,
        color: Color(0xFF0891B2),
        bgColor: Color(0xFFCFFAFE),
        badgeColor: Color(0xFFA5F3FC),
        label: 'Languages',
      );
    }
    if (lower.contains('tech') || lower.contains('code') || lower.contains('comput') || lower.contains('robot')) {
      return const SubjectVisual(
        icon: Icons.computer_rounded,
        color: Color(0xFF4338CA),
        bgColor: Color(0xFFE0E7FF),
        badgeColor: Color(0xFFC7D2FE),
        label: 'Technology',
      );
    }

    if (isCore) {
      return const SubjectVisual(
        icon: Icons.school_rounded,
        color: Color(0xFF0F766E),
        bgColor: Color(0xFFCCFBF1),
        badgeColor: Color(0xFF99F6E4),
        label: 'Core Subject',
      );
    }

    return const SubjectVisual(
      icon: Icons.star_rounded,
      color: Color(0xFFCA8A04),
      bgColor: Color(0xFFFEF9C3),
      badgeColor: Color(0xFFFEF08A),
      label: 'Elective',
    );
  }
}

/// Visual styling bundle for a subject
class SubjectVisual {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final Color badgeColor;
  final String label;

  const SubjectVisual({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.badgeColor,
    required this.label,
  });
}

/// A cheerful child avatar with gradient glow and friendly icon
class KidsChildAvatar extends StatelessWidget {
  final int childId;
  final String name;
  final double radius;
  final bool showBadge;

  const KidsChildAvatar({
    super.key,
    required this.childId,
    required this.name,
    this.radius = 24,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, startColor, endColor) = KidsVisuals.getAvatarStyle(childId);
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [startColor, endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: startColor.withValues(alpha: 0.28),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: radius * 0.9,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}
