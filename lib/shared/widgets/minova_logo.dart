import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

enum MinovaLogoLayout { iconOnly, horizontal, vertical }
enum MinovaLogoTheme { fullColorDark, fullColorLight, monochrome }

/// High-fidelity vector-rendered MINOVA Brand Logo based on the official brand identity.
/// Features:
/// 1. Mining Helmet (Protection)
/// 2. Illuminated Headlamp with outward radiant light beam (Awareness)
/// 3. Cyan Shield with bold 'M' Monogram (Safety & Strength)
/// 4. Layered Geological Coal Strata (Underground Mining)
class MinovaLogo extends StatelessWidget {
  final double size;
  final MinovaLogoLayout layout;
  final MinovaLogoTheme theme;
  final bool showTagline;
  final String? customTagline;
  final bool useRasterAsset;

  const MinovaLogo({
    super.key,
    this.size = 64,
    this.layout = MinovaLogoLayout.vertical,
    this.theme = MinovaLogoTheme.fullColorDark,
    this.showTagline = true,
    this.customTagline,
    this.useRasterAsset = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget emblem;
    final assetPath = layout == MinovaLogoLayout.iconOnly
        ? 'assets/icons/minova_emblem.png'
        : 'assets/icons/minova_logo.png';

    if (useRasterAsset && theme != MinovaLogoTheme.monochrome) {
      emblem = Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _MinovaLogoPainter(theme: theme),
          ),
        ),
      );
    } else {
      emblem = SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _MinovaLogoPainter(theme: theme),
        ),
      );
    }

    if (layout == MinovaLogoLayout.iconOnly) {
      return emblem;
    }

    final isDark = theme == MinovaLogoTheme.fullColorDark;
    final primaryTextColor = isDark ? Colors.white : AppColors.textHighEmphasis;

    final wordmark = MinovaWordmark(
      fontSize: size * 0.38,
      color: primaryTextColor,
      showTagline: showTagline,
      tagline: customTagline,
      crossAxisAlignment: layout == MinovaLogoLayout.horizontal
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
    );

    if (layout == MinovaLogoLayout.horizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          emblem,
          SizedBox(width: size * 0.25),
          wordmark,
        ],
      );
    }

    // Vertical layout
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        emblem,
        SizedBox(height: size * 0.16),
        wordmark,
      ],
    );
  }
}

/// Standalone and reusable MINOVA Wordmark with the official styling
/// and cyan chevron accent on the letter 'A'.
class MinovaWordmark extends StatelessWidget {
  final double fontSize;
  final Color? color;
  final bool showTagline;
  final String? tagline;
  final CrossAxisAlignment crossAxisAlignment;

  const MinovaWordmark({
    super.key,
    this.fontSize = 20,
    this.color,
    this.showTagline = false,
    this.tagline,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = color ?? AppColors.textHighEmphasis;
    final taglineText = tagline ?? 'SAFER MINES. A STRONGER TOMORROW.';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          'MINOVA',
          style: AppTypography.headlineSm.copyWith(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.2,
            color: textColor,
          ),
        ),
        if (showTagline) ...[
          SizedBox(height: fontSize * 0.14),
          Text(
            taglineText.toUpperCase(),
            style: AppTypography.labelSm.copyWith(
              color: AppColors.textMediumEmphasis,
              fontWeight: FontWeight.w700,
              fontSize: (fontSize * 0.38).clamp(8.0, 13.0),
              letterSpacing: 1.2,
            ),
          ),
        ],
      ],
    );
  }
}

class _MinovaLogoPainter extends CustomPainter {
  final MinovaLogoTheme theme;

  _MinovaLogoPainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final isMono = theme == MinovaLogoTheme.monochrome;
    final helmetColor = isMono ? const Color(0xFF64748B) : AppColors.amberGold;
    final helmetShadowColor = isMono ? const Color(0xFF475569) : const Color(0xFF78350F);
    final shieldLeftColor = isMono ? const Color(0xFF94A3B8) : const Color(0xFF00D2FF);
    final shieldRightColor = isMono ? const Color(0xFF64748B) : const Color(0xFF0284C7);
    final shieldFillColor = const Color(0xFF0F131A);

    // ── 1. Headlamp Outward Spotlight Beam ──
    if (!isMono) {
      final beamPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            const Color(0xFFFFE885).withAlpha(240),
            AppColors.amberGold.withAlpha(180),
            AppColors.safetyOrange.withAlpha(80),
            AppColors.safetyOrange.withAlpha(0),
          ],
        ).createShader(Rect.fromLTWH(w * 0.60, h * 0.05, w * 0.40, h * 0.35));

      final beamPath = Path()
        ..moveTo(w * 0.60, h * 0.16)
        ..lineTo(w * 0.99, h * 0.06)
        ..lineTo(w * 0.94, h * 0.30)
        ..close();
      canvas.drawPath(beamPath, beamPaint);
    }

    // ── 2. The Angular Protection Shield ──
    final shieldPath = Path()
      ..moveTo(w * 0.20, h * 0.34)
      ..lineTo(w * 0.80, h * 0.34)
      ..lineTo(w * 0.80, h * 0.65)
      ..lineTo(w * 0.50, h * 0.92)
      ..lineTo(w * 0.20, h * 0.65)
      ..close();

    // Shield background fill
    canvas.drawPath(shieldPath, Paint()..color = shieldFillColor);

    // Left Wing (Vibrant Cyan)
    final leftShield = Path()
      ..moveTo(w * 0.20, h * 0.34)
      ..lineTo(w * 0.50, h * 0.34)
      ..lineTo(w * 0.50, h * 0.92)
      ..lineTo(w * 0.20, h * 0.65)
      ..close();
    canvas.drawPath(
      leftShield,
      Paint()
        ..color = shieldLeftColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.08
        ..strokeJoin = StrokeJoin.round,
    );

    // Right Wing (Deep Blue)
    final rightShield = Path()
      ..moveTo(w * 0.50, h * 0.34)
      ..lineTo(w * 0.80, h * 0.34)
      ..lineTo(w * 0.80, h * 0.65)
      ..lineTo(w * 0.50, h * 0.92)
      ..close();
    canvas.drawPath(
      rightShield,
      Paint()
        ..color = shieldRightColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.08
        ..strokeJoin = StrokeJoin.round,
    );

    // ── 3. Faceted Geological Coal Strata (Under 'M') ──
    final strataLeft = Path()
      ..moveTo(w * 0.36, h * 0.77)
      ..lineTo(w * 0.50, h * 0.68)
      ..lineTo(w * 0.50, h * 0.88)
      ..close();
    canvas.drawPath(strataLeft, Paint()..color = isMono ? const Color(0xFF64748B) : const Color(0xFF475569));

    final strataRight = Path()
      ..moveTo(w * 0.50, h * 0.68)
      ..lineTo(w * 0.64, h * 0.77)
      ..lineTo(w * 0.50, h * 0.88)
      ..close();
    canvas.drawPath(strataRight, Paint()..color = isMono ? const Color(0xFF334155) : const Color(0xFF1E293B));

    // ── 4. Bold White 'M' Monogram ──
    final mPath = Path()
      ..moveTo(w * 0.30, h * 0.66)
      ..lineTo(w * 0.30, h * 0.43)
      ..lineTo(w * 0.40, h * 0.43)
      ..lineTo(w * 0.50, h * 0.56)
      ..lineTo(w * 0.60, h * 0.43)
      ..lineTo(w * 0.70, h * 0.43)
      ..lineTo(w * 0.70, h * 0.66)
      ..lineTo(w * 0.62, h * 0.66)
      ..lineTo(w * 0.62, h * 0.52)
      ..lineTo(w * 0.50, h * 0.68)
      ..lineTo(w * 0.38, h * 0.52)
      ..lineTo(w * 0.38, h * 0.66)
      ..close();

    canvas.drawPath(mPath, Paint()..color = Colors.white);

    // ── 5. Mining Hardhat / Helmet (Isometric Dome) ──
    // Rear Ear Guard Notch
    final earGuard = Path()
      ..moveTo(w * 0.19, h * 0.33)
      ..quadraticBezierTo(w * 0.18, h * 0.26, w * 0.25, h * 0.24)
      ..lineTo(w * 0.28, h * 0.33)
      ..close();
    canvas.drawPath(earGuard, Paint()..color = const Color(0xFFB45309));

    // Dome Main
    final helmetPath = Path()
      ..moveTo(w * 0.23, h * 0.34)
      ..lineTo(w * 0.77, h * 0.34)
      ..lineTo(w * 0.73, h * 0.28)
      ..quadraticBezierTo(w * 0.68, h * 0.11, w * 0.48, h * 0.11)
      ..quadraticBezierTo(w * 0.26, h * 0.11, w * 0.23, h * 0.28)
      ..close();
    canvas.drawPath(helmetPath, Paint()..color = helmetColor);

    // Contour Crease
    final contour = Path()
      ..moveTo(w * 0.23, h * 0.32)
      ..quadraticBezierTo(w * 0.48, h * 0.22, w * 0.75, h * 0.32)
      ..lineTo(w * 0.77, h * 0.34)
      ..lineTo(w * 0.23, h * 0.34)
      ..close();
    canvas.drawPath(contour, Paint()..color = helmetShadowColor);

    // Chrome Highlight Brim
    final brim = Path()
      ..moveTo(w * 0.21, h * 0.35)
      ..lineTo(w * 0.79, h * 0.35)
      ..lineTo(w * 0.76, h * 0.33)
      ..lineTo(w * 0.24, h * 0.33)
      ..close();
    canvas.drawPath(brim, Paint()..color = Colors.white.withAlpha(220));

    // ── 6. Illuminated Headlamp ──
    final lampCenter = Offset(w * 0.58, h * 0.20);
    final lampRadius = w * 0.08;

    canvas.drawCircle(
      lampCenter,
      lampRadius,
      Paint()..color = const Color(0xFF0F172A),
    );

    canvas.drawCircle(
      lampCenter,
      lampRadius * 0.85,
      Paint()..color = const Color(0xFF1E293B),
    );

    canvas.drawCircle(
      lampCenter,
      lampRadius * 0.65,
      Paint()..color = isMono ? Colors.white : Colors.amberAccent,
    );

    if (!isMono) {
      canvas.drawCircle(
        lampCenter,
        lampRadius * 0.40,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MinovaLogoPainter oldDelegate) =>
      oldDelegate.theme != theme;
}
