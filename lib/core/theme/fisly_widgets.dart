import 'package:material_ui/material_ui.dart';

import 'app_theme.dart';

/// Curated chart and category accent palette.
const fislyPalette = <Color>[
  Color(0xFF4F46E5), // Electric Indigo
  Color(0xFF10B981), // Emerald
  Color(0xFF0EA5E9), // Sky Cyan
  Color(0xFFF59E0B), // Warm Amber
  Color(0xFFEC4899), // Rose Pink
  Color(0xFF8B5CF6), // Violet
  Color(0xFF14B8A6), // Teal
  Color(0xFF64748B), // Slate
];

/// Maps category names to an icon and accent color for visual scanning.
class FislyCategoryVisual {
  const FislyCategoryVisual({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  static FislyCategoryVisual fromName(String? name) {
    final normalized = (name ?? '').trim().toLowerCase();
    if (normalized.contains('yemek') ||
        normalized.contains('restoran') ||
        normalized.contains('kafe')) {
      return const FislyCategoryVisual(
        icon: Icons.restaurant_rounded,
        color: Color(0xFFF59E0B),
      );
    }
    if (normalized.contains('market') || normalized.contains('gıda')) {
      return const FislyCategoryVisual(
        icon: Icons.shopping_basket_rounded,
        color: Color(0xFF10B981),
      );
    }
    if (normalized.contains('ulaşım') ||
        normalized.contains('yakıt') ||
        normalized.contains('taksi')) {
      return const FislyCategoryVisual(
        icon: Icons.directions_car_rounded,
        color: Color(0xFF0EA5E9),
      );
    }
    if (normalized.contains('fatura') || normalized.contains('abonelik')) {
      return const FislyCategoryVisual(
        icon: Icons.bolt_rounded,
        color: Color(0xFF8B5CF6),
      );
    }
    if (normalized.contains('alışveriş') || normalized.contains('giyim')) {
      return const FislyCategoryVisual(
        icon: Icons.shopping_bag_rounded,
        color: Color(0xFFEC4899),
      );
    }
    if (normalized.contains('sağlık') || normalized.contains('eczane')) {
      return const FislyCategoryVisual(
        icon: Icons.medical_services_rounded,
        color: Color(0xFFEF4444),
      );
    }
    if (normalized.contains('eğlence')) {
      return const FislyCategoryVisual(
        icon: Icons.confirmation_number_rounded,
        color: Color(0xFF14B8A6),
      );
    }
    return const FislyCategoryVisual(
      icon: Icons.receipt_long_rounded,
      color: Color(0xFF4F46E5),
    );
  }
}

/// Soft tinted rounded-square icon badge for categories and transactions.
class FislyIconBadge extends StatelessWidget {
  const FislyIconBadge({
    required this.icon,
    required this.color,
    this.size = 44,
    this.iconSize = 22,
    this.radius = 14,
    super.key,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}

/// Consistent modal bottom sheet header with icon badge and optional action.
class FislySheetHeader extends StatelessWidget {
  const FislySheetHeader({
    required this.title,
    required this.icon,
    this.subtitle,
    this.trailing,
    this.accentColor,
    super.key,
  });

  final String title;
  final IconData icon;
  final String? subtitle;
  final Widget? trailing;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.fislyColors;
    final badgeColor = accentColor ?? colors.accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            FislyIconBadge(icon: icon, color: badgeColor),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            ?trailing,
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 10),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

/// Subtle pill-shaped status or metric badge.
class FislyPillBadge extends StatelessWidget {
  const FislyPillBadge({
    required this.label,
    required this.foreground,
    required this.background,
    this.icon,
    super.key,
  });

  final String label;
  final Color foreground;
  final Color background;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
