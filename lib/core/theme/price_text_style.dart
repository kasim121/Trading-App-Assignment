import 'package:flutter/material.dart';

import '../theme/app_theme.dart';


TextStyle priceTextStyle({
  double fontSize = 14,
  FontWeight fontWeight = FontWeight.w500,
  Color color = AppColors.textPrimary,
}) {
  return TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
    letterSpacing: 0.1,
    height: 1.2,
  );
}

String formatChangePercent(double value) {
  final sign = value > 0 ? '+' : '';
  return '$sign${value.toStringAsFixed(2)}%';
}
