import 'package:flutter/material.dart';
import 'package:pink_diary_calendar/theme/app_colors.dart';
import 'package:pink_diary_calendar/theme/app_theme.dart';

class WarmPageScaffold extends StatelessWidget {
  const WarmPageScaffold({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final warmColors = Theme.of(context).extension<WarmThemeColors>();

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: warmColors?.pageGradient ?? AppColors.pageGradient,
      ),
      child: Stack(
        children: [
          _SoftDecorations(
            primary: warmColors?.primary ?? const Color(0xFF7FA3AF),
            secondary: warmColors?.secondary ?? const Color(0xFF86A8A0),
            soft: warmColors?.soft ?? const Color(0xFFFAF8F2),
          ),
          SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftDecorations extends StatelessWidget {
  const _SoftDecorations({
    required this.primary,
    required this.secondary,
    required this.soft,
  });

  final Color primary;
  final Color secondary;
  final Color soft;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: 36,
            right: 28,
            child: Icon(
              Icons.auto_awesome_rounded,
              color: secondary.withValues(alpha: 0.36),
              size: 28,
            ),
          ),
          Positioned(
            top: 118,
            left: 22,
            child: Icon(
              Icons.eco_outlined,
              color: primary.withValues(alpha: 0.18),
              size: 34,
            ),
          ),
          Positioned(
            bottom: 142,
            right: 34,
            child: Icon(
              Icons.nightlight_round,
              color: secondary.withValues(alpha: 0.2),
              size: 36,
            ),
          ),
          Positioned(
            bottom: 92,
            left: 48,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: soft.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
