import 'package:flutter/material.dart';
import 'package:pink_diary_calendar/theme/app_colors.dart';

class WarmPageScaffold extends StatelessWidget {
  const WarmPageScaffold({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.pageGradient),
      child: Stack(
        children: [
          const _SoftDecorations(),
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
  const _SoftDecorations();

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
              color: AppColors.butter.withValues(alpha: 0.85),
              size: 28,
            ),
          ),
          Positioned(
            top: 118,
            left: 22,
            child: Icon(
              Icons.favorite_rounded,
              color: AppColors.rose.withValues(alpha: 0.22),
              size: 34,
            ),
          ),
          Positioned(
            bottom: 142,
            right: 34,
            child: Icon(
              Icons.nightlight_round,
              color: AppColors.lavenderDeep.withValues(alpha: 0.2),
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
                color: AppColors.sage.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
