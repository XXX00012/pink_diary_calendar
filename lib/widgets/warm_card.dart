import 'package:flutter/material.dart';
import 'package:pink_diary_calendar/theme/app_colors.dart';
import 'package:pink_diary_calendar/theme/app_theme.dart';

class WarmCard extends StatelessWidget {
  const WarmCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.color,
    this.border,
    this.borderRadius = const BorderRadius.all(Radius.circular(28)),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final BoxBorder? border;
  final BorderRadiusGeometry borderRadius;

  @override
  Widget build(BuildContext context) {
    final warmColors = Theme.of(context).extension<WarmThemeColors>();
    final primary = warmColors?.primary ?? const Color(0xFF7FA3AF);
    final cardColor = warmColors?.card ?? AppColors.milk;

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? cardColor.withValues(alpha: 0.88),
        borderRadius: borderRadius,
        border:
            border ?? Border.all(color: Colors.white.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.09),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.64),
            blurRadius: 8,
            offset: const Offset(-3, -3),
          ),
        ],
      ),
      child: child,
    );
  }
}
