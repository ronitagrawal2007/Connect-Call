import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Icon + wordmark lockup. Used full-size on splash, small in headers.
/// Light variant for white backgrounds, dark variant for navy backgrounds.
class BrandMark extends StatelessWidget {
  final double iconSize;
  final bool dark;
  final bool showTagline;

  const BrandMark({
    super.key,
    this.iconSize = 72,
    this.dark = false,
    this.showTagline = true,
  });

  const BrandMark.small({
    super.key,
    this.iconSize = 48,
    this.dark = false,
    this.showTagline = true,
  });

  @override
  Widget build(BuildContext context) {
    final Color connectColor =
        dark ? Colors.white : AppTheme.darkNavy;
    const Color callColor = AppTheme.primary;
    final Color taglineColor = dark
        ? const Color(0xFFB8C0E0)
        : const Color(0xFF6B7280);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LogoIcon(size: iconSize, dark: dark),
        const SizedBox(height: 12),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: iconSize * 0.32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              fontFamily: 'Roboto',
            ),
            children: [
              TextSpan(
                text: 'Connect',
                style: TextStyle(color: connectColor),
              ),
              const TextSpan(
                text: 'Call',
                style: TextStyle(color: callColor),
              ),
            ],
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: 4),
          Text(
            'Connect with anyone, anywhere.',
            style: TextStyle(
              fontSize: iconSize * 0.13,
              fontWeight: FontWeight.w400,
              color: taglineColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _LogoIcon extends StatelessWidget {
  final double size;
  final bool dark;
  const _LogoIcon({required this.size, required this.dark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LogoPainter(dark: dark),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  final bool dark;
  _LogoPainter({required this.dark});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;
    final double r = w * 0.44;
    final double stroke = w * 0.18;

    // Gradient for C + handset
    final Rect rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    final Paint gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: dark
            ? [const Color(0xFF8EA8FF), AppTheme.primary]
            : [const Color(0xFF5B8DEF), AppTheme.primary],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    // Draw C: 270 degree arc, open on right (~30deg gap)
    const double startAngle = 0.55; // radians offset
    const double sweep = 5.2; // ~298 deg
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      startAngle,
      sweep,
      false,
      gradientPaint,
    );

    // Handset silhouette
    final double hr = w * 0.28;
    final Offset handsetCenter = Offset(cx + w * 0.04, cy + h * 0.02);
    final Paint handsetPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: dark
            ? [const Color(0xFF8EA8FF), const Color(0xFF6B9FFF)]
            : [AppTheme.primary, const Color(0xFF3355FF)],
      ).createShader(Rect.fromCircle(center: handsetCenter, radius: hr))
      ..style = PaintingStyle.fill;

    // Approximate handset as two rounded rects + curve
    // Upper earpiece
    final RRect top = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(handsetCenter.dx - w * 0.12, handsetCenter.dy - h * 0.18),
          width: w * 0.22,
          height: h * 0.14),
      Radius.circular(w * 0.07),
    );
    // Lower mouthpiece
    final RRect bottom = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(handsetCenter.dx + w * 0.12, handsetCenter.dy + h * 0.18),
          width: w * 0.26,
          height: h * 0.14),
      Radius.circular(w * 0.07),
    );
    // Connecting curve
    final Path curve = Path()
      ..moveTo((handsetCenter.dx - w * 0.12) + w * 0.06, (handsetCenter.dy - h * 0.18) + h * 0.06)
      ..quadraticBezierTo(
          handsetCenter.dx - w * 0.02, handsetCenter.dy + h * 0.02,
          (handsetCenter.dx + w * 0.12) - w * 0.06, (handsetCenter.dy + h * 0.18) - h * 0.06)
      ..lineTo((handsetCenter.dx + w * 0.12) + w * 0.02, (handsetCenter.dy + h * 0.18) - h * 0.02)
      ..quadraticBezierTo(
          handsetCenter.dx + w * 0.04, handsetCenter.dy - h * 0.02,
          (handsetCenter.dx - w * 0.12) + w * 0.10, (handsetCenter.dy - h * 0.18) + h * 0.04)
      ..close();

    canvas.save();
    canvas.translate(handsetCenter.dx, handsetCenter.dy);
    canvas.rotate(-0.35);
    canvas.translate(-handsetCenter.dx, -handsetCenter.dy);
    canvas.drawRRect(top, handsetPaint);
    canvas.drawRRect(bottom, handsetPaint);
    canvas.drawPath(curve, handsetPaint);
    canvas.restore();

    // Signal arcs - brighter cyan-blue
    final Paint wavePaint = Paint()
      ..color = dark ? const Color(0xFF7EC8FF) : const Color(0xFF5BC0FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.032
      ..strokeCap = StrokeCap.round;

    final Offset waveOrigin = Offset(
        handsetCenter.dx + w * 0.22, handsetCenter.dy - h * 0.08);
    for (int i = 0; i < 3; i++) {
      final double radius = w * (0.07 + i * 0.06);
      final Rect arcRect =
          Rect.fromCircle(center: waveOrigin, radius: radius);
      canvas.drawArc(arcRect, -0.6, 1.1, false, wavePaint);
    }

    // Subtle inner highlight on C (lighter edge)
    if (!dark) {
      final Paint highlight = Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * 0.35
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx - w * 0.04, cy - h * 0.04), radius: r),
        startAngle + 0.15,
        sweep * 0.45,
        false,
        highlight,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
