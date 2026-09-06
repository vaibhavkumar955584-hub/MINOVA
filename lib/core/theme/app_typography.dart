import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  static TextStyle get displayLg => GoogleFonts.spaceGrotesk(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 40 / 32,
        letterSpacing: -0.64,
        color: AppColors.textHighEmphasis,
      );

  static TextStyle get headlineLg => GoogleFonts.spaceGrotesk(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 34 / 26,
        letterSpacing: -0.26,
        color: AppColors.textHighEmphasis,
      );

  static TextStyle get headlineMd => GoogleFonts.spaceGrotesk(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 30 / 22,
        color: AppColors.textHighEmphasis,
      );

  static TextStyle get headlineSm => GoogleFonts.spaceGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 26 / 18,
        letterSpacing: 0.18,
        color: AppColors.textHighEmphasis,
      );

  static TextStyle get bodyLg => GoogleFonts.notoSans(
        fontSize: 17,
        fontWeight: FontWeight.w500,
        height: 26 / 17,
        color: AppColors.textHighEmphasis,
      );

  static TextStyle get bodyMd => GoogleFonts.notoSans(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 24 / 15,
        letterSpacing: 0.15,
        color: AppColors.textMediumEmphasis,
      );

  static TextStyle get bodySm => GoogleFonts.notoSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 20 / 13,
        letterSpacing: 0.13,
        color: AppColors.textMediumEmphasis,
      );

  static TextStyle get labelLg => GoogleFonts.spaceGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 22 / 16,
        letterSpacing: 0.8,
        color: AppColors.textHighEmphasis,
      );

  static TextStyle get labelMd => GoogleFonts.spaceGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 18 / 14,
        letterSpacing: 0.56,
        color: AppColors.textHighEmphasis,
      );

  static TextStyle get labelSm => GoogleFonts.spaceGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        height: 16 / 12,
        letterSpacing: 0.72,
        color: AppColors.textHighEmphasis,
      );

  static TextStyle get bilingualCue => GoogleFonts.notoSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 16 / 12,
        letterSpacing: 0.24,
        color: AppColors.textBilingualCue,
      );
}
