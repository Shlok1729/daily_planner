import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:daily_planner/screens/auth_wrapper.dart';

/// FIXED: Splash screen with guaranteed navigation (no hanging)
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _animationFailed = false;
  bool _hasNavigated = false; // Prevent multiple navigation attempts

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();

    // CRITICAL: Start navigation immediately (no waiting)
    _initializeAndNavigate();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// CRITICAL: Initialize and navigate with timeout protection
  Future<void> _initializeAndNavigate() async {
    try {
      // Multiple fallbacks to ensure navigation happens
      await Future.any([
        _performNavigationWithDelay(),
        _emergencyNavigation(),
      ]);
    } catch (e) {
      debugPrint('⚠️ Splash navigation error: $e');
      _forceNavigation();
    }
  }

  /// Primary navigation path with short delay
  Future<void> _performNavigationWithDelay() async {
    // Short delay for splash animation (reduced from 3 seconds to 1.5)
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted && !_hasNavigated) {
      _navigateToAuthWrapper();
    }
  }

  /// Emergency navigation as backup (triggers after 3 seconds)
  Future<void> _emergencyNavigation() async {
    await Future.delayed(const Duration(seconds: 3));

    if (mounted && !_hasNavigated) {
      debugPrint('🚨 Emergency navigation triggered');
      _navigateToAuthWrapper();
    }
  }

  /// Force navigation (last resort)
  void _forceNavigation() {
    if (mounted && !_hasNavigated) {
      debugPrint('🚨 Force navigation triggered');
      _navigateToAuthWrapper();
    }
  }

  /// Navigate to AuthWrapper with error protection
  void _navigateToAuthWrapper() {
    if (_hasNavigated) return; // Prevent multiple navigation attempts

    try {
      _hasNavigated = true;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const AuthWrapper(),
        ),
      );

      debugPrint('✅ Successfully navigated to AuthWrapper');
    } catch (e) {
      debugPrint('❌ Navigation error: $e');
      // Reset flag to allow retry
      _hasNavigated = false;

      // Try again after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !_hasNavigated) {
          _navigateToAuthWrapper();
        }
      });
    }
  }

  Widget _buildFallbackIcon() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.checklist_rtl,
                size: 60,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLottieAnimation() {
    // Try to load local animation first, then network as fallback
    return Container(
      width: 200,
      height: 200,
      child: Lottie.asset(
        'assets/animations/productivity_splash.json',
        width: 200,
        height: 200,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // First fallback: try network animation
          return Lottie.network(
            'https://assets10.lottiefiles.com/packages/lf20_ystsffqy.json',
            width: 200,
            height: 200,
            fit: BoxFit.contain,
            errorBuilder: (context, networkError, networkStackTrace) {
              // Final fallback: custom animated icon
              if (mounted) {
                setState(() {
                  _animationFailed = true;
                });
              }
              return _buildFallbackIcon();
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo animation with fallback
              _animationFailed ? _buildFallbackIcon() : _buildLottieAnimation(),

              const SizedBox(height: 32),

              // App name with animation
              Text(
                'Daily Planner',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 200.ms)
                  .slideY(begin: 0.2, end: 0, duration: 600.ms),

              const SizedBox(height: 8),

              Text(
                'Focus • Organize • Achieve',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.8,
                ),
              )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 600.ms)
                  .slideY(begin: 0.2, end: 0, duration: 600.ms),

              const SizedBox(height: 60),

              // Loading indicator with custom styling
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 600.ms, duration: 600.ms),

              const SizedBox(height: 16),

              Text(
                'Starting your productivity workspace...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              )
                  .animate()
                  .fadeIn(delay: 800.ms, duration: 600.ms),

              const SizedBox(height: 20),

              // Emergency navigation button (only shows after 4 seconds)
              FutureBuilder(
                future: Future.delayed(const Duration(seconds: 4)),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done && !_hasNavigated) {
                    return TextButton(
                      onPressed: _forceNavigation,
                      child: Text(
                        'Tap if stuck loading',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ).animate().fadeIn(duration: 300.ms);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}