import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:daily_planner/screens/auth_screen_enhanced.dart';
import 'package:daily_planner/utils/icon_renderer.dart';

class OnboardingScreen extends StatefulWidget {
  final bool skipOnboarding;

  const OnboardingScreen({
    Key? key,
    this.skipOnboarding = false,
  }) : super(key: key);

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // FIXED: Animation controllers for enhanced intro
  late AnimationController _iconAnimationController;
  late AnimationController _timerAnimationController;
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _timerRotationAnimation;

  final List<OnboardingItem> _items = [
    OnboardingItem(
      title: 'Task Management',
      description: 'Organize your tasks efficiently with our intuitive task management system and smart prioritization.',
      animationUrl: 'https://assets4.lottiefiles.com/packages/lf20_z4cshyhb.json',
      fallbackIcon: IconRenderer.taskFilled,
      primaryColor: Colors.blue,
    ),
    OnboardingItem(
      title: 'Focus Mode',
      description: 'Stay focused and productive with our Pomodoro timer and focus sessions. Block distracting apps automatically.',
      animationUrl: 'https://assets6.lottiefiles.com/packages/lf20_rovf9gzu.json',
      fallbackIcon: IconRenderer.timerFilled,
      primaryColor: Colors.orange,
      hasTimerSymbol: true, // FIXED: Added timer symbol flag
    ),
    OnboardingItem(
      title: 'Smart Assistant',
      description: 'Get help and suggestions from our intelligent chatbot assistant for better productivity.',
      animationUrl: 'https://assets10.lottiefiles.com/packages/lf20_zrqthn6w.json',
      fallbackIcon: IconRenderer.chatFilled,
      primaryColor: Colors.purple,
    ),
  ];

  @override
  void initState() {
    super.initState();

    // FIXED: Initialize animations
    _iconAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _timerAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _iconScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _iconAnimationController,
      curve: Curves.elasticOut,
    ));

    _timerRotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _timerAnimationController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _iconAnimationController.forward();
    _timerAnimationController.repeat();

    // If we should skip onboarding, navigate directly to auth
    if (widget.skipOnboarding) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToAuth();
      });
    }
  }

  @override
  void dispose() {
    _iconAnimationController.dispose();
    _timerAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If skipping onboarding, show a loading indicator
    if (widget.skipOnboarding) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.05),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: () => _navigateToAuth(),
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              // Main content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _items.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                    // Restart animations on page change
                    _iconAnimationController.reset();
                    _iconAnimationController.forward();
                  },
                  itemBuilder: (context, index) {
                    return _buildOnboardingPage(_items[index], index);
                  },
                ),
              ),

              // Page indicator
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _items.length,
                        (index) => _buildDotIndicator(index),
                  ),
                ),
              ),

              // Next/Get Started button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentPage == _items.length - 1) {
                        _navigateToAuth();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _currentPage == _items.length - 1 ? 'Get Started' : 'Next',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingItem item, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // FIXED: Enhanced animation section with timer symbol
          SizedBox(
            height: 300,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background circle
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        item.primaryColor.withOpacity(0.1),
                        item.primaryColor.withOpacity(0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                // Main icon/animation
                AnimatedBuilder(
                  animation: _iconScaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _iconScaleAnimation.value,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: item.primaryColor.withOpacity(0.1),
                          border: Border.all(
                            color: item.primaryColor.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: _buildPageIcon(item, index),
                      ),
                    );
                  },
                ),

                // FIXED: Timer symbol animation for Focus Mode page
                if (item.hasTimerSymbol && index == 1) ...[
                  Positioned(
                    top: 40,
                    right: 40,
                    child: AnimatedBuilder(
                      animation: _timerRotationAnimation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _timerRotationAnimation.value * 2 * 3.14159,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.orange.withOpacity(0.9),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.3),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.timer,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Additional timer indicators
                  Positioned(
                    bottom: 60,
                    left: 30,
                    child: AnimatedBuilder(
                      animation: _timerAnimationController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 0.8 + 0.4 * _timerAnimationController.value,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red.withOpacity(0.8),
                            ),
                            child: const Icon(
                              Icons.access_time,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    bottom: 80,
                    right: 60,
                    child: AnimatedBuilder(
                      animation: _timerAnimationController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.2 - 0.4 * _timerAnimationController.value,
                          child: Container(
                            width: 35,
                            height: 35,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green.withOpacity(0.8),
                            ),
                            child: const Icon(
                              Icons.schedule,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                // Floating particles effect
                ...List.generate(6, (particleIndex) {
                  return Positioned(
                    top: 50 + (particleIndex * 40).toDouble(),
                    left: 20 + (particleIndex * 60).toDouble(),
                    child: AnimatedBuilder(
                      animation: _iconAnimationController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(
                            10 * (0.5 - _iconAnimationController.value),
                            20 * (0.5 - _iconAnimationController.value),
                          ),
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: item.primaryColor.withOpacity(0.3),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 48),

          // Title
          Text(
            item.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: item.primaryColor,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: const Duration(milliseconds: 300))
              .slideY(begin: 0.3, end: 0),

          const SizedBox(height: 16),

          // Description
          Text(
            item.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              height: 1.6,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: const Duration(milliseconds: 500))
              .slideY(begin: 0.3, end: 0),
        ],
      ),
    );
  }

  Widget _buildPageIcon(OnboardingItem item, int index) {
    return Center(
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: item.primaryColor.withOpacity(0.1),
        ),
        child: Center(
          child: item.animationUrl != null
              ? Lottie.network(
            item.animationUrl!,
            width: 80,
            height: 80,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                item.fallbackIcon,
                size: 60,
                color: item.primaryColor,
              );
            },
          )
              : Icon(
            item.fallbackIcon,
            size: 60,
            color: item.primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildDotIndicator(int index) {
    final isActive = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 32 : 12,
      height: 12,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: isActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.primary.withOpacity(0.3),
      ),
    );
  }

  void _navigateToAuth() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
        const AuthScreenEnhanced(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }
}

class OnboardingItem {
  final String title;
  final String description;
  final String? animationUrl;
  final IconData fallbackIcon;
  final Color primaryColor;
  final bool hasTimerSymbol;

  OnboardingItem({
    required this.title,
    required this.description,
    this.animationUrl,
    required this.fallbackIcon,
    this.primaryColor = Colors.blue,
    this.hasTimerSymbol = false,
  });
}