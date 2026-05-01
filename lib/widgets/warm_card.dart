import 'package:flutter/material.dart';
import 'package:pink_diary_calendar/theme/app_colors.dart';

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
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.milk.withValues(alpha: 0.88),
        borderRadius: borderRadius,
        border:
            border ?? Border.all(color: Colors.white.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: AppColors.rose.withValues(alpha: 0.12),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.7),
            blurRadius: 10,
            offset: const Offset(-4, -4),
          ),
        ],
      ),
      child: child,
    );
  }
}
