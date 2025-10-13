import 'package:flutter/material.dart';

class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // ============================================================================
  // PRIMARY COLORS
  // ============================================================================

  // Light theme primary colors
  static const Color primaryLight = Color(0xFF6366F1); // Indigo
  static const Color primaryDark = Color(0xFF8B5CF6); // Purple

  // ============================================================================
  // ACCENT COLORS
  // ============================================================================

  // Light theme accent colors
  static const Color accentLight = Color(0xFF06B6D4); // Cyan
  static const Color accentDark = Color(0xFF10B981); // Emerald

  // ============================================================================
  // BACKGROUND COLORS
  // ============================================================================

  // Light theme backgrounds
  static const Color backgroundLight = Color(0xFFF8FAFC); // Slate 50
  static const Color backgroundDark = Color(0xFF0F172A); // Slate 900

  // ============================================================================
  // SURFACE/CARD COLORS
  // ============================================================================

  // Light theme cards and surfaces
  static const Color cardLight = Color(0xFFFFFFFF); // White
  static const Color cardDark = Color(0xFF1E293B); // Slate 800

  // ============================================================================
  // TEXT COLORS
  // ============================================================================

  // Light theme text colors
  static const Color textPrimaryLight = Color(0xFF1E293B); // Slate 800
  static const Color textSecondaryLight = Color(0xFF64748B); // Slate 500
  static const Color textTertiaryLight = Color(0xFF94A3B8); // Slate 400

  // Dark theme text colors
  static const Color textPrimaryDark = Color(0xFFF1F5F9); // Slate 100
  static const Color textSecondaryDark = Color(0xFFCBD5E1); // Slate 300
  static const Color textTertiaryDark = Color(0xFF94A3B8); // Slate 400

  // ============================================================================
  // STATUS COLORS
  // ============================================================================

  // Success colors
  static const Color successLight = Color(0xFF22C55E); // Green 500
  static const Color successDark = Color(0xFF16A34A); // Green 600

  // Error colors
  static const Color errorLight = Color(0xFFEF4444); // Red 500
  static const Color errorDark = Color(0xFFDC2626); // Red 600

  // Warning colors
  static const Color warningLight = Color(0xFFF59E0B); // Amber 500
  static const Color warningDark = Color(0xFFD97706); // Amber 600

  // Info colors
  static const Color infoLight = Color(0xFF3B82F6); // Blue 500
  static const Color infoDark = Color(0xFF2563EB); // Blue 600

  // ============================================================================
  // FUNCTIONAL COLORS
  // ============================================================================

  // Priority colors - ADDED MISSING GETTERS
  static const Color priorityHigh = Color(0xFFEF4444); // Red 500
  static const Color priorityMedium = Color(0xFFF59E0B); // Amber 500
  static const Color priorityLow = Color(0xFF22C55E); // Green 500

  // ADDED: Missing priority getters
  static Color get highPriority => priorityHigh;
  static Color get mediumPriority => priorityMedium;
  static Color get lowPriority => priorityLow;

  // Category colors
  static const Color categoryWork = Color(0xFF8B5CF6); // Purple 500
  static const Color categoryPersonal = Color(0xFF06B6D4); // Cyan 500
  static const Color categoryHealth = Color(0xFF10B981); // Emerald 500
  static const Color categoryOther = Color(0xFF6B7280); // Gray 500

  // Focus mode colors
  static const Color focusActive = Color(0xFF8B5CF6); // Purple 500
  static const Color focusInactive = Color(0xFF6B7280); // Gray 500

  // App blocker colors
  static const Color blockedApp = Color(0xFFEF4444); // Red 500
  static const Color allowedApp = Color(0xFF22C55E); // Green 500

  // ============================================================================
  // EISENHOWER MATRIX COLORS - ADDED MISSING GETTERS
  // ============================================================================

  // Eisenhower Matrix quadrant colors
  static const Color _urgentImportantColor = Color(0xFFEF4444); // Red 500
  static const Color _urgentNotImportantColor = Color(0xFFF59E0B); // Amber 500
  static const Color _notUrgentImportantColor = Color(0xFF3B82F6); // Blue 500
  static const Color _notUrgentNotImportantColor = Color(0xFF6B7280); // Gray 500

  // ADDED: Missing Eisenhower Matrix getters
  static Color get urgentImportant => _urgentImportantColor;
  static Color get urgentNotImportant => _urgentNotImportantColor;
  static Color get notUrgentImportant => _notUrgentImportantColor;
  static Color get notUrgentNotImportant => _notUrgentNotImportantColor;

  // ============================================================================
  // GRADIENT COLORS
  // ============================================================================

  // Primary gradients
  static const LinearGradient primaryGradientLight = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradientDark = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Success gradients
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Error gradients
  static const LinearGradient errorGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Warning gradients
  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ============================================================================
  // CHART COLORS
  // ============================================================================

  static const List<Color> chartColors = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF8B5CF6), // Purple
    Color(0xFF06B6D4), // Cyan
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFFEF4444), // Red
    Color(0xFF3B82F6), // Blue
    Color(0xFFF97316), // Orange
    Color(0xFFEC4899), // Pink
    Color(0xFF84CC16), // Lime
  ];

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Get priority color based on priority level
  static Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return priorityHigh;
      case 'medium':
        return priorityMedium;
      case 'low':
        return priorityLow;
      default:
        return priorityMedium;
    }
  }

  /// Get category color based on category type
  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'work':
        return categoryWork;
      case 'personal':
        return categoryPersonal;
      case 'health':
        return categoryHealth;
      case 'other':
        return categoryOther;
      default:
        return categoryOther;
    }
  }

  /// Get status color based on status type
  static Color getStatusColor(String status, {bool isDark = false}) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'completed':
        return isDark ? successDark : successLight;
      case 'error':
      case 'failed':
        return isDark ? errorDark : errorLight;
      case 'warning':
      case 'pending':
        return isDark ? warningDark : warningLight;
      case 'info':
      case 'in_progress':
        return isDark ? infoDark : infoLight;
      default:
        return isDark ? textSecondaryDark : textSecondaryLight;
    }
  }

  /// Get Eisenhower Matrix color based on quadrant
  static Color getEisenhowerColor(String quadrant) {
    switch (quadrant.toLowerCase()) {
      case 'urgentimportant':
        return urgentImportant;
      case 'urgentnotimportant':
        return urgentNotImportant;
      case 'noturgentimportant':
        return notUrgentImportant;
      case 'noturgentnotimportant':
        return notUrgentNotImportant;
      default:
        return notUrgentNotImportant;
    }
  }

  /// Get chart color by index
  static Color getChartColor(int index) {
    return chartColors[index % chartColors.length];
  }

  /// Get complementary color
  static Color getComplementaryColor(Color color) {
    final hslColor = HSLColor.fromColor(color);
    final complementary = hslColor.withHue((hslColor.hue + 180) % 360);
    return complementary.toColor();
  }

  /// Get color with opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity.clamp(0.0, 1.0));
  }

  /// Darken color by percentage
  static Color darken(Color color, double percent) {
    final hslColor = HSLColor.fromColor(color);
    final lightness = (hslColor.lightness - percent).clamp(0.0, 1.0);
    return hslColor.withLightness(lightness).toColor();
  }

  /// Lighten color by percentage
  static Color lighten(Color color, double percent) {
    final hslColor = HSLColor.fromColor(color);
    final lightness = (hslColor.lightness + percent).clamp(0.0, 1.0);
    return hslColor.withLightness(lightness).toColor();
  }

  /// Get color based on theme brightness
  static Color getThemeColor(Color lightColor, Color darkColor, bool isDark) {
    return isDark ? darkColor : lightColor;
  }
}