import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_planner/constants/app_colors.dart';
import 'package:daily_planner/screens/eisenhower_matrix_screen.dart';

class EisenhowerMatrix extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // In a real app, you would get this data from a provider
    final urgentImportantCount = 3;
    final urgentNotImportantCount = 2;
    final notUrgentImportantCount = 4;
    final notUrgentNotImportantCount = 1;

    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => EisenhowerMatrixScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          // FIXED: Better responsive height calculation
          constraints: BoxConstraints(
            minHeight: 260,
            maxHeight: MediaQuery.of(context).size.height * 0.35,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: cardColor,
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.4)
                    : Colors.black.withOpacity(0.08),
                blurRadius: isDark ? 12 : 8,
                offset: Offset(0, isDark ? 6 : 4),
                spreadRadius: isDark ? 1 : 0,
              ),
            ],
            border: isDark
                ? Border.all(
              color: Colors.grey[700]!.withOpacity(0.3),
              width: 1,
            )
                : null,
          ),
          child: Column(
            children: [
              // FIXED: Better header with improved spacing
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      Theme.of(context).colorScheme.secondary.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.grid_view,
                        color: Theme.of(context).colorScheme.primary,
                        size: 22,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Eisenhower Matrix',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Priority quadrants',
                            style: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),

              // FIXED: Matrix grid with proper constraints to prevent overflow
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(12), // Reduced padding
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final availableHeight = constraints.maxHeight;
                      final availableWidth = constraints.maxWidth;

                      // Ensure minimum space for quadrants
                      if (availableHeight < 120 || availableWidth < 200) {
                        return Center(
                          child: Text(
                            'Matrix view requires more space',
                            style: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      return Column(
                        children: [
                          // Top row
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    margin: EdgeInsets.only(right: 6, bottom: 6),
                                    child: _buildQuadrant(
                                      context,
                                      'DO',
                                      'Do First',
                                      urgentImportantCount,
                                      AppColors.urgentImportant,
                                      Icons.priority_high,
                                      availableWidth,
                                      availableHeight,
                                      isDark,
                                      isTopLeft: true,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    margin: EdgeInsets.only(left: 6, bottom: 6),
                                    child: _buildQuadrant(
                                      context,
                                      'DECIDE',
                                      'Schedule',
                                      notUrgentImportantCount,
                                      AppColors.notUrgentImportant,
                                      Icons.calendar_today,
                                      availableWidth,
                                      availableHeight,
                                      isDark,
                                      isTopRight: true,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Bottom row
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    margin: EdgeInsets.only(right: 6, top: 6),
                                    child: _buildQuadrant(
                                      context,
                                      'DELEGATE',
                                      'Delegate',
                                      urgentNotImportantCount,
                                      AppColors.urgentNotImportant,
                                      Icons.person_outline,
                                      availableWidth,
                                      availableHeight,
                                      isDark,
                                      isBottomLeft: true,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    margin: EdgeInsets.only(left: 6, top: 6),
                                    child: _buildQuadrant(
                                      context,
                                      'DELETE',
                                      'Eliminate',
                                      notUrgentNotImportantCount,
                                      AppColors.notUrgentNotImportant,
                                      Icons.delete_outline,
                                      availableWidth,
                                      availableHeight,
                                      isDark,
                                      isBottomRight: true,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              // FIXED: Better positioned tap hint
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.2)
                              : Colors.black.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.touch_app,
                            size: 12,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Tap to manage',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black54,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuadrant(
      BuildContext context,
      String title,
      String subtitle,
      int count,
      Color color,
      IconData icon,
      double availableWidth,
      double availableHeight,
      bool isDark, {
        bool isTopLeft = false,
        bool isTopRight = false,
        bool isBottomLeft = false,
        bool isBottomRight = false,
      }) {
    // FIXED: Better responsive sizing calculations to prevent overflow
    final quadrantWidth = (availableWidth - 12) / 2;
    final quadrantHeight = (availableHeight - 12) / 2;

    // FIXED: More conservative sizing to prevent overflow
    double titleFontSize = 11;
    double subtitleFontSize = 9;
    double iconSize = 16;
    double badgeSize = 18;

    // Only increase sizes if there's sufficient space
    if (quadrantWidth > 120 && quadrantHeight > 60) {
      titleFontSize = 12;
      subtitleFontSize = 10;
      iconSize = 18;
      badgeSize = 20;
    }

    if (quadrantWidth > 160 && quadrantHeight > 80) {
      titleFontSize = 13;
      subtitleFontSize = 11;
      iconSize = 20;
      badgeSize = 22;
    }

    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(isDark ? 0.4 : 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(isDark ? 0.2 : 0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(8), // Reduced padding
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // FIXED: Prevent overflow
          children: [
            // FIXED: Flexible icon container
            Flexible(
              flex: 2,
              child: Container(
                width: iconSize + 8, // Reduced padding
                height: iconSize + 8,
                constraints: BoxConstraints(
                  maxWidth: quadrantWidth * 0.4,
                  maxHeight: quadrantHeight * 0.3,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(isDark ? 0.3 : 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: iconSize,
                ),
              ),
            ),

            SizedBox(height: 4), // Reduced spacing

            // FIXED: Flexible title with better text handling
            Flexible(
              flex: 1,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: titleFontSize,
                    color: color,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ),
            ),

            // FIXED: Flexible subtitle with overflow handling
            Flexible(
              flex: 1,
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: subtitleFontSize,
                  color: isDark
                      ? Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8)
                      : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            SizedBox(height: 4), // Reduced spacing

            // FIXED: Flexible count badge with constraints
            Flexible(
              flex: 1,
              child: Container(
                width: badgeSize,
                height: badgeSize,
                constraints: BoxConstraints(
                  maxWidth: quadrantWidth * 0.25,
                  maxHeight: quadrantHeight * 0.2,
                ),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: FittedBox(
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        color: _getContrastColor(color),
                        fontWeight: FontWeight.bold,
                        fontSize: badgeSize * 0.45, // Slightly smaller
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FIXED: Better contrast color calculation
  Color _getContrastColor(Color backgroundColor) {
    // Calculate luminance to determine if we need light or dark text
    final luminance = backgroundColor.computeLuminance();

    // Use a more sophisticated contrast calculation
    if (luminance > 0.6) {
      return Colors.black87;
    } else if (luminance > 0.4) {
      return Colors.black;
    } else {
      return Colors.white;
    }
  }
}