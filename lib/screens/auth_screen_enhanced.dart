import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:daily_planner/providers/auth_provider.dart' as auth_prov;
import 'package:daily_planner/widgets/auth/oauth_buttons.dart';
// FIXED: Renamed import with a prefix to avoid ambiguity
import 'package:daily_planner/widgets/common/custom_button.dart' as button;
import 'package:daily_planner/widgets/common/custom_text_field.dart';
import 'package:daily_planner/widgets/auth/password_field_with_strength.dart';
import 'package:daily_planner/screens/main_navigation_screen.dart';
import 'package:daily_planner/services/auth_service.dart' as auth_svc;
import 'package:daily_planner/utils/auth_utils.dart';

// ============================================================================
// AUTH SCREEN ENHANCED (FIXED - NO IMPORT CONFLICTS)
// ============================================================================

/// Enhanced authentication screen with improved UI and OAuth support
/// FIXED: All import conflicts resolved by using prefixed imports
class AuthScreenEnhanced extends ConsumerStatefulWidget {
  final bool isSignUp;

  const AuthScreenEnhanced({
    Key? key,
    this.isSignUp = false,
  }) : super(key: key);

  @override
  ConsumerState<AuthScreenEnhanced> createState() => _AuthScreenEnhancedState();
}

class _AuthScreenEnhancedState extends ConsumerState<AuthScreenEnhanced>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // State
  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.isSignUp;
    _setupAnimations();
  }

  void _setupAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    // Start animations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeController.forward();
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _errorMessage = null;
    });

    // Animate the transition
    _fadeController.reverse().then((_) {
      _fadeController.forward();
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authNotifier = ref.read(auth_prov.authProvider.notifier);

      if (_isSignUp) {
        final result = await authNotifier.signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
        );

        if (result.success && mounted) {
          _showSuccessMessage('Account created successfully!');
          await Future.delayed(const Duration(seconds: 1));
          _navigateToMain();
        } else {
          _setError(result.error ?? 'Sign up failed');
        }
      } else {
        final result = await authNotifier.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (result.success && mounted) {
          _showSuccessMessage('Welcome back!');
          await Future.delayed(const Duration(seconds: 1));
          _navigateToMain();
        } else {
          _setError(result.error ?? 'Sign in failed');
        }
      }
    } catch (e) {
      _setError('An unexpected error occurred: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleOAuthResult(auth_svc.OAuthResult result) async {
    if (result.success) {
      _showSuccessMessage('Welcome!');
      await Future.delayed(const Duration(seconds: 1));
      _navigateToMain();
    } else {
      _setError(result.error ?? 'OAuth sign in failed');
    }
  }

  Future<void> _handleGuestSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authNotifier = ref.read(auth_prov.authProvider.notifier);
      final result = await authNotifier.signInAsGuest();

      if (result.success && mounted) {
        _showSuccessMessage('Welcome! You\'re signed in as a guest.');
        await Future.delayed(const Duration(seconds: 1));
        _navigateToMain();
      } else {
        _setError(result.error ?? 'Guest sign in failed');
      }
    } catch (e) {
      _setError('Failed to sign in as guest: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _setError(String error) {
    if (mounted) {
      setState(() {
        _errorMessage = error;
      });
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _navigateToMain() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const MainNavigationScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // FIXED: Using prefixed authProvider to avoid conflicts
    final authState = ref.watch(auth_prov.authProvider);

    // Redirect if already authenticated
    if (authState.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToMain();
      });
    }

    return Scaffold(
      body: Container(
        decoration: _buildBackgroundDecoration(),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  _buildAppBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: _buildMainContent(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildBackgroundDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Theme.of(context).primaryColor.withOpacity(0.1),
          Theme.of(context).scaffoldBackgroundColor,
          Theme.of(context).primaryColor.withOpacity(0.05),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back',
          ),
          const Spacer(),
          if (_isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          _buildOAuthSection(),
          const SizedBox(height: 24),
          _buildDivider(),
          const SizedBox(height: 24),
          _buildEmailForm(),
          const SizedBox(height: 24),
          _buildActionButtons(),
          const SizedBox(height: 16),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Icon(
          Icons.task_alt,
          size: 64,
          color: Theme.of(context).primaryColor,
        ).animate().scale(delay: 300.ms, duration: 600.ms),
        const SizedBox(height: 16),
        Text(
          _isSignUp ? 'Create Account' : 'Welcome Back',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3, end: 0),
        const SizedBox(height: 8),
        Text(
          _isSignUp
              ? 'Set up your productivity workspace'
              : 'Continue your productivity journey',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 500.ms),
      ],
    );
  }

  Widget _buildOAuthSection() {
    return Column(
      children: [
        OAuthButtons(
          onResult: _handleOAuthResult,
          isSignUp: _isSignUp,
          showPlaceholderNote: true,
        ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
        const SizedBox(height: 16),
        _buildGuestButton(),
      ],
    );
  }

  Widget _buildGuestButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _handleGuestSignIn,
        icon: const Icon(Icons.person_outline),
        label: const Text('Continue as Guest'),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey[300]!),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 700.ms);
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[300])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey[300])),
      ],
    ).animate().fadeIn(delay: 800.ms);
  }

  Widget _buildEmailForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (_isSignUp) ...[
            CustomTextField(
              controller: _nameController,
              label: 'Full Name',
              prefixIcon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your full name';
                }
                return null;
              },
            ).animate().fadeIn(delay: 900.ms).slideX(begin: -0.1, end: 0),
            const SizedBox(height: 16),
          ],

          CustomTextField(
            controller: _emailController,
            label: 'Email Address',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email address';
              }
              if (!AuthUtils.isValidEmail(value.trim())) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ).animate().fadeIn(delay: 1000.ms).slideX(begin: -0.1, end: 0),

          const SizedBox(height: 16),

          PasswordFieldWithStrength(
            controller: _passwordController,
            label: 'Password',
            showStrengthIndicator: _isSignUp,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (_isSignUp && !AuthUtils.isStrongPassword(value)) {
                return 'Password must be at least 8 characters with uppercase, lowercase, and numbers';
              }
              return null;
            },
          ).animate().fadeIn(delay: 1100.ms).slideX(begin: -0.1, end: 0),

          if (_isSignUp) ...[
            const SizedBox(height: 16),
            CustomTextField(
              controller: _confirmPasswordController,
              label: 'Confirm Password',
              prefixIcon: Icons.lock_outline,
              obscureText: _obscureConfirmPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ).animate().fadeIn(delay: 1200.ms).slideX(begin: -0.1, end: 0),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().shake(),
          const SizedBox(height: 16),
        ],

        // FIXED: Use button.CustomButton to avoid ambiguity
        button.CustomButton(
          // FIXED: Specify text parameter explicitly
          text: _isSignUp ? 'Create Account' : 'Sign In',
          // FIXED: Convert null to a void function for onPressed
          onPressed: _isLoading ? () {} : () => _handleSubmit(),
          isLoading: _isLoading,
        ).animate().fadeIn(delay: 1300.ms).slideY(begin: 0.2, end: 0),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        TextButton(
          onPressed: _isLoading ? null : _toggleAuthMode,
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                TextSpan(
                  text: _isSignUp
                      ? 'Already have an account? '
                      : 'Don\'t have an account? ',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                TextSpan(
                  text: _isSignUp ? 'Sign In' : 'Sign Up',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 1400.ms),

        const SizedBox(height: 8),

        if (!_isSignUp) ...[
          TextButton(
            onPressed: _isLoading ? null : () {
              // TODO: Implement forgot password
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Forgot password feature coming soon!'),
                ),
              );
            },
            child: Text(
              'Forgot Password?',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ).animate().fadeIn(delay: 1500.ms),
        ],

        const SizedBox(height: 16),

        Text(
          'By continuing, you agree to our Terms of Service and Privacy Policy',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 1600.ms),
      ],
    );
  }
}

// ============================================================================
// UTILITY CLASSES FOR AUTH VALIDATION
// ============================================================================

/// Authentication utilities for validation
class AuthUtils {
  /// Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  /// Check if password meets strength requirements
  static bool isStrongPassword(String password) {
    return password.length >= 8 &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[0-9]'));
  }

  /// Get password strength score (0-4)
  static int getPasswordStrength(String password) {
    int score = 0;

    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;

    return score.clamp(0, 4);
  }

  /// Get password strength description
  static String getPasswordStrengthText(String password) {
    final strength = getPasswordStrength(password);

    switch (strength) {
      case 0:
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      default:
        return 'Weak';
    }
  }

  /// Get password strength color
  static Color getPasswordStrengthColor(String password) {
    final strength = getPasswordStrength(password);

    switch (strength) {
      case 0:
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow[700]!;
      case 4:
        return Colors.green;
      default:
        return Colors.red;
    }
  }

  /// Generate auth error message
  static String getAuthErrorMessage(String error) {
    if (error.contains('email-already-in-use')) {
      return 'An account with this email already exists';
    } else if (error.contains('weak-password')) {
      return 'Password is too weak';
    } else if (error.contains('invalid-email')) {
      return 'Please enter a valid email address';
    } else if (error.contains('user-not-found')) {
      return 'No account found with this email';
    } else if (error.contains('wrong-password')) {
      return 'Incorrect password';
    } else if (error.contains('user-disabled')) {
      return 'This account has been disabled';
    } else if (error.contains('too-many-requests')) {
      return 'Too many failed attempts. Please try again later';
    } else if (error.contains('network')) {
      return 'Network error. Please check your connection';
    }

    return 'An unexpected error occurred. Please try again';
  }
}