import 'package:flutter/material.dart';

class DesignConstants {
  static const Color primaryColor = Color(0xFF5B67CA);
  static const Color primaryDarkColor = Color(0xFF5B4FCF);
  static const Color secondaryColor = Color(0xFF8B5CF6);
  static const Color accentColor = Color(0xFF06B6D4);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);

  static const Color textPrimary = Color(0xFF1A1F36);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);

  static const Color backgroundPrimary = Color(0xFFF8F9FA);
  static const Color backgroundSecondary = Color(0xFFF7F8FC);
  static const Color cardBackground = Colors.white;

  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color dividerColor = Color(0xFFF3F4F6);

  static const double fontSizeLarge = 22.0;
  static const double fontSizeTitle = 20.0;
  static const double fontSizeSubtitle = 18.0;
  static const double fontSizeBody = 16.0;
  static const double fontSizeMedium = 14.0;
  static const double fontSizeSmall = 12.0;
  static const double fontSizeTiny = 10.0;

  static const FontWeight fontWeightBold = FontWeight.w700;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightRegular = FontWeight.w400;

  static const double iconSizeLarge = 28.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeSmall = 20.0;
  static const double iconSizeTiny = 18.0;

  static const double containerSizeLarge = 80.0;
  static const double containerSizeMedium = 56.0;
  static const double containerSizeSmall = 48.0;
  static const double containerSizeTiny = 40.0;
  static const double containerSizeMini = 36.0;

  static const double radiusLarge = 20.0;
  static const double radiusMedium = 16.0;
  static const double radiusSmall = 12.0;
  static const double radiusTiny = 8.0;

  static const double spacingLarge = 24.0;
  static const double spacingMedium = 16.0;
  static const double spacingSmall = 12.0;
  static const double spacingTiny = 8.0;
  static const double spacingMini = 4.0;

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get cardShadowStrong => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  static const TextStyle textStyleTitle = TextStyle(
    fontSize: fontSizeTitle,
    fontWeight: fontWeightBold,
    color: textPrimary,
  );

  static const TextStyle textStyleSubtitle = TextStyle(
    fontSize: fontSizeSubtitle,
    fontWeight: fontWeightSemiBold,
    color: textPrimary,
  );

  static const TextStyle textStyleBody = TextStyle(
    fontSize: fontSizeBody,
    fontWeight: fontWeightMedium,
    color: textPrimary,
  );

  static const TextStyle textStyleCaption = TextStyle(
    fontSize: fontSizeSmall,
    fontWeight: fontWeightRegular,
    color: textSecondary,
  );

  static const TextStyle textStyleTiny = TextStyle(
    fontSize: fontSizeTiny,
    fontWeight: fontWeightRegular,
    color: textLight,
  );

  static Widget buildIconContainer({
    required IconData icon,
    required Color color,
    double size = containerSizeTiny,
    double iconSize = iconSizeSmall,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(radiusTiny),
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }

  static BoxDecoration get cardDecoration => BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(radiusMedium),
    boxShadow: cardShadow,
  );

  static BoxDecoration get primaryButtonDecoration => BoxDecoration(
    color: primaryColor,
    borderRadius: BorderRadius.circular(radiusSmall),
  );

  static BoxDecoration get secondaryButtonDecoration => BoxDecoration(
    color: dividerColor,
    borderRadius: BorderRadius.circular(radiusSmall),
  );
}
