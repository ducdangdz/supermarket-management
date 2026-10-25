import 'package:flutter/material.dart';

class AppColors {
  // Primary & Secondary Brand Colors (Phong cách Siêu thị bán lẻ hiện đại)
  static const Color primary = Color(0xFF0F4C81); // Classic Navy Blue
  static const Color primaryDark = Color(0xFF0A3358);
  static const Color primaryLight = Color(0xFFE8F1F8);
  static const Color secondary = Color(0xFF00A86B); // Fresh Emerald Green
  static const Color accent = Color(0xFFFF9F1C); // Warm Tangerine

  // Status Colors (Trực quan hóa mặt bằng & chấm công)
  static const Color statusPresent = Color(0xFF2EC4B6); // Xanh lá - Đã check in đúng vị trí
  static const Color statusLate = Color(0xFFFF9F1C); // Vàng cam - Đi muộn
  static const Color statusAbsent = Color(0xFFE71D36); // Đỏ - Vắng mặt / Sai vị trí
  static const Color statusPending = Color(0xFF6C757D); // Xám - Chờ / Chưa có ca
  static const Color statusInvalid = Color(0xFFD90429); // Đỏ thẫm - Bất thường vị trí

  // Neutral Colors
  static const Color background = Color(0xFFF4F6F9);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1D2939);
  static const Color textSecondary = Color(0xFF667085);
  static const Color textMuted = Color(0xFF98A2B3);
  static const Color divider = Color(0xFFEAECF0);
  static const Color border = Color(0xFFD0D5DD);

  // Work Area Category Colors
  static const Color areaCashier = Color(0xFFE0F2FE); // Light Sky
  static const Color areaFreshFood = Color(0xFFDCFCE7); // Light Mint
  static const Color areaGrocery = Color(0xFFFEF3C7); // Light Amber
  static const Color areaWarehouse = Color(0xFFEDE9FE); // Light Purple
  static const Color areaSecurity = Color(0xFFFFE4E6); // Light Rose
  static const Color areaService = Color(0xFFF1F5F9); // Light Slate
}
