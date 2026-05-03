import 'package:flutter/material.dart';
import 'package:pink_diary_calendar/theme/app_colors.dart';
import 'package:pink_diary_calendar/theme/app_theme.dart';

class WarmPageTitle extends StatelessWidget {
  const WarmPageTitle({
    required this.title,
    required this.subtitle,
    required this.icon,
    super.key,
    this.iconColor,
    this.trailing,
    this.keepSubtitleOnOneLine = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color? iconColor;
  final Widget? trailing;
  final bool keepSubtitleOnOneLine;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final warmColors = Theme.of(context).extension<WarmThemeColors>();
    final primary = iconColor ?? warmColors?.primary ?? const Color(0xFF7FA3AF);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: (warmColors?.primarySoft ?? AppColors.milk).withValues(
              alpha: 0.82,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
          ),
          child: Icon(icon, color: primary, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: textTheme.headlineSmall),
              const SizedBox(height: 5),
              if (keepSubtitleOnOneLine)
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      subtitle,
                      maxLines: 1,
                      style: textTheme.bodyMedium?.copyWith(
                        color: warmColors?.textSecondary ?? AppColors.muted,
                      ),
                    ),
                  ),
                )
              else
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    color: warmColors?.textSecondary ?? AppColors.muted,
                  ),
                ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}

class LineCatDecoration extends StatelessWidget {
  const LineCatDecoration({super.key, this.width = 62, this.height = 52});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final warmColors = Theme.of(context).extension<WarmThemeColors>();
    final color = (warmColors?.illustrationColor ?? AppColors.muted).withValues(
      alpha: 0.7,
    );

    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: _LineCatPainter(color)),
    );
  }
}

class _LineCatPainter extends CustomPainter {
  const _LineCatPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    final leftEar = Path()
      ..moveTo(w * 0.27, h * 0.30)
      ..lineTo(w * 0.33, h * 0.08)
      ..quadraticBezierTo(w * 0.40, h * 0.22, w * 0.44, h * 0.29);
    canvas.drawPath(leftEar, paint);

    final rightEar = Path()
      ..moveTo(w * 0.56, h * 0.29)
      ..quadraticBezierTo(w * 0.61, h * 0.20, w * 0.69, h * 0.08)
      ..lineTo(w * 0.73, h * 0.31);
    canvas.drawPath(rightEar, paint);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.40),
        width: w * 0.48,
        height: h * 0.44,
      ),
      paint,
    );

    paint.style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.40, h * 0.38), 1.45, paint);
    canvas.drawCircle(Offset(w * 0.59, h * 0.38), 1.45, paint);
    canvas.drawCircle(Offset(w * 0.50, h * 0.45), 1.25, paint);
    paint.style = PaintingStyle.stroke;

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(w * 0.46, h * 0.48),
        width: w * 0.10,
        height: h * 0.08,
      ),
      0.1,
      1.15,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(w * 0.54, h * 0.48),
        width: w * 0.10,
        height: h * 0.08,
      ),
      1.9,
      1.15,
      false,
      paint,
    );

    canvas.drawLine(
      Offset(w * 0.33, h * 0.45),
      Offset(w * 0.18, h * 0.40),
      paint,
    );
    canvas.drawLine(
      Offset(w * 0.33, h * 0.49),
      Offset(w * 0.18, h * 0.50),
      paint,
    );
    canvas.drawLine(
      Offset(w * 0.67, h * 0.45),
      Offset(w * 0.82, h * 0.40),
      paint,
    );
    canvas.drawLine(
      Offset(w * 0.67, h * 0.49),
      Offset(w * 0.82, h * 0.50),
      paint,
    );

    final body = Path()
      ..moveTo(w * 0.39, h * 0.61)
      ..quadraticBezierTo(w * 0.23, h * 0.74, w * 0.35, h * 0.88)
      ..quadraticBezierTo(w * 0.50, h * 0.98, w * 0.66, h * 0.86)
      ..quadraticBezierTo(w * 0.76, h * 0.74, w * 0.62, h * 0.61);
    canvas.drawPath(body, paint);

    final tail = Path()
      ..moveTo(w * 0.65, h * 0.78)
      ..quadraticBezierTo(w * 0.92, h * 0.75, w * 0.82, h * 0.53)
      ..quadraticBezierTo(w * 0.75, h * 0.41, w * 0.86, h * 0.35);
    canvas.drawPath(tail, paint);

    canvas.drawLine(
      Offset(w * 0.43, h * 0.87),
      Offset(w * 0.36, h * 0.87),
      paint,
    );
    canvas.drawLine(
      Offset(w * 0.57, h * 0.87),
      Offset(w * 0.64, h * 0.87),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _LineCatPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
