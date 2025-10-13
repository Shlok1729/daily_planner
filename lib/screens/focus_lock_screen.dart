import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:daily_planner/models/blocked_app.dart';
import 'package:daily_planner/screens/app_blocker_selection_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_planner/providers/app_blocker_provider.dart';

class FocusLockScreen extends ConsumerStatefulWidget {
  final Duration remainingTime;
  final VoidCallback? onBreakFocus;

  const FocusLockScreen({
    Key? key,
    required this.remainingTime,
    this.onBreakFocus,
  }) : super(key: key);

  @override
  _FocusLockScreenState createState() => _FocusLockScreenState();
}

class _FocusLockScreenState extends ConsumerState<FocusLockScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  Timer? _timer;
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _remainingTime = widget.remainingTime;

    // Setup animations
    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: Duration(seconds: 10),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_rotationController);

    // Start animations
    _pulseController.repeat(reverse: true);
    _rotationController.repeat();

    // Start countdown timer
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime.inSeconds > 0) {
          _remainingTime = _remainingTime - Duration(seconds: 1);
        } else {
          _timer?.cancel();
          _onFocusComplete();
        }
      });
    });
  }

  void _onFocusComplete() {
    // Focus session completed
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Color(0xFF2D5A4A)
            : Color(0xFFE0F2F1),
        title: Row(
          children: [
            Text('🎉', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text(
              'Focus Complete!',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          ],
        ),
        content: Text(
          'Great job! You successfully completed your focus session.',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.8)
                : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(
              'Awesome!',
              style: TextStyle(color: Color(0xFF4ECDC4)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _remainingTime.inMinutes.toString().padLeft(2, '0');
    final seconds = (_remainingTime.inSeconds % 60).toString().padLeft(2, '0');
    final hours = _remainingTime.inHours.toString().padLeft(2, '0');

    final appBlockerState = ref.watch(appBlockerProvider);
    final blockedAppsCount = appBlockerState.blockedApps.where((app) => app.isBlocked).length;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Color(0xFF4C1D95), // Purple
              Color(0xFF2D1B69),
              Color(0xFF1E1B4B),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Spacer(),

                // Lock icon with animation
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: AnimatedBuilder(
                        animation: _rotationAnimation,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _rotationAnimation.value * 0.1,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Color(0xFF4ECDC4).withOpacity(0.5),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF4ECDC4).withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.lock,
                                size: 60,
                                color: Color(0xFF4ECDC4),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),

                SizedBox(height: 40),

                // "Tap to lock in" text
                Text(
                  'Focus Mode Active',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                SizedBox(height: 20),

                // Countdown timer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTimeUnit(hours, 'hrs'),
                    _buildTimeSeparator(),
                    _buildTimeUnit(minutes, 'min'),
                    _buildTimeSeparator(),
                    _buildTimeUnit(seconds, 'sec'),
                  ],
                ),

                SizedBox(height: 50),

                // Block Apps section
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Color(0xFF4ECDC4).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.block,
                              color: Color(0xFF4ECDC4),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Apps Blocked',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '$blockedAppsCount apps currently blocked',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$blockedAppsCount',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // App selection buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildAppButton('📱', 'Social', () => _selectApps(AppCategory.social)),
                          _buildAppButton('🎮', 'Games', () => _selectApps(AppCategory.games)),
                          _buildAppButton('🎬', 'Entertainment', () => _selectApps(AppCategory.entertainment)),
                        ],
                      ),
                    ],
                  ),
                ),

                Spacer(),

                // Bottom buttons
                Row(
                  children: [
                    // Settings button
                    Expanded(
                      child: _buildBottomButton(
                        Icons.settings,
                            () => _openSettings(),
                      ),
                    ),
                    SizedBox(width: 16),

                    // Break Focus button
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _showBreakFocusDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.withOpacity(0.2),
                            foregroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            side: BorderSide(color: Colors.red.withOpacity(0.5)),
                          ),
                          child: Text(
                            'Break Focus',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: 16),

                    // Menu button
                    Expanded(
                      child: _buildBottomButton(
                        Icons.menu,
                            () => _openMenu(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeUnit(String value, String label) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSeparator() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        ':',
        style: TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAppButton(String emoji, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: TextStyle(fontSize: 24)),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton(IconData icon, VoidCallback onTap) {
    return Container(
      height: 56,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.1),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
        ),
        child: Icon(icon),
      ),
    );
  }

  void _selectApps(AppCategory category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AppBlockerSelectionScreen(),
      ),
    );
  }

  void _openSettings() {
    // Open settings
  }

  void _openMenu() {
    // Open menu
  }

  void _showBreakFocusDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Color(0xFF2D2D44)
            : Colors.white,
        title: Row(
          children: [
            Text('⚠️', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text(
              'Break Focus?',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to end your focus session early?',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.8)
                : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Continue Focusing',
              style: TextStyle(color: Color(0xFF4ECDC4)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onBreakFocus?.call();
              Navigator.pop(context);
            },
            child: Text(
              'End Session',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}