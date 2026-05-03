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
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color? iconColor;
  final Widget? trailing;

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

class LineDogDecoration extends StatelessWidget {
  const LineDogDecoration({super.key, this.width = 84, this.height = 58});

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
      child: CustomPaint(painter: _LineDogPainter(color)),
    );
  }
}

class _LineDogPainter extends CustomPainter {
  const _LineDogPainter(this.color);

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

    final body = Path()
      ..moveTo(w * 0.25, h * 0.63)
      ..quadraticBezierTo(w * 0.44, h * 0.43, w * 0.66, h * 0.55)
      ..quadraticBezierTo(w * 0.82, h * 0.64, w * 0.73, h * 0.78)
      ..quadraticBezierTo(w * 0.53, h * 0.92, w * 0.28, h * 0.76)
      ..quadraticBezierTo(w * 0.18, h * 0.70, w * 0.25, h * 0.63);
    canvas.drawPath(body, paint);

    final head = Path()
      ..moveTo(w * 0.19, h * 0.52)
      ..quadraticBezierTo(w * 0.08, h * 0.37, w * 0.2, h * 0.22)
      ..quadraticBezierTo(w * 0.33, h * 0.10, w * 0.43, h * 0.26)
      ..quadraticBezierTo(w * 0.51, h * 0.44, w * 0.38, h * 0.58);
    canvas.drawPath(head, paint);

    final ear = Path()
      ..moveTo(w * 0.29, h * 0.18)
      ..quadraticBezierTo(w * 0.34, h * 0.03, w * 0.43, h * 0.17)
      ..quadraticBezierTo(w * 0.38, h * 0.25, w * 0.33, h * 0.28);
    canvas.drawPath(ear, paint);

    canvas.drawCircle(
      Offset(w * 0.26, h * 0.37),
      1.6,
      paint..style = PaintingStyle.fill,
    );
    paint.style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(w * 0.18, h * 0.45),
        width: w * 0.12,
        height: h * 0.12,
      ),
      0.15,
      1.1,
      false,
      paint,
    );

    final tail = Path()
      ..moveTo(w * 0.73, h * 0.57)
      ..quadraticBezierTo(w * 0.90, h * 0.40, w * 0.82, h * 0.25);
    canvas.drawPath(tail, paint);

    canvas.drawLine(
      Offset(w * 0.42, h * 0.78),
      Offset(w * 0.38, h * 0.93),
      paint,
    );
    canvas.drawLine(
      Offset(w * 0.61, h * 0.79),
      Offset(w * 0.66, h * 0.93),
      paint,
    );
    canvas.drawLine(
      Offset(w * 0.34, h * 0.93),
      Offset(w * 0.43, h * 0.93),
      paint,
    );
    canvas.drawLine(
      Offset(w * 0.63, h * 0.93),
      Offset(w * 0.72, h * 0.93),
      paint,
    );

    final bookPaint = Paint()
      ..color = color.withValues(alpha: 0.58)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final book = Path()
      ..moveTo(w * 0.50, h * 0.34)
      ..lineTo(w * 0.62, h * 0.30)
      ..lineTo(w * 0.68, h * 0.40)
      ..lineTo(w * 0.56, h * 0.44)
      ..close();
    canvas.drawPath(book, bookPaint);
    canvas.drawLine(
      Offset(w * 0.59, h * 0.32),
      Offset(w * 0.63, h * 0.42),
      bookPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _LineDogPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
