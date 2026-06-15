import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nanei/core/theme/app_color.dart';

Widget buildEmptyState({
  required IconData icon,
  required String message,
  String? buttonText,
  VoidCallback? onPressed,
}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          Stack(
            alignment: Alignment.center,
            children: [
              // Cercle extérieur dégradé flou
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColor.kPrimary.withValues(alpha: 0.12),
                      AppColor.kPrimary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
              // Cercle milieu
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColor.kAccentSoft,
                ),
              ),
              // Icône
              Icon(
                icon,
                size: 36,
                color: AppColor.kPrimary,
              ),
            ],
          ),

          const SizedBox(height: 24),

          Text(
            'Rien ici pour l\'instant',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColor.kGrayscaleDark100,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            message,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColor.kGrayscale40,
              fontWeight: FontWeight.w400,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),

          if (buttonText != null && onPressed != null) ...[
            const SizedBox(height: 32),
            GestureDetector(
              onTap: onPressed,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColor.kPrimary, AppColor.kPrimaryDark],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColor.kPrimary.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      buttonText,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
