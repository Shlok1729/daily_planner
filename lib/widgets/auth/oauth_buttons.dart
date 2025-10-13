import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:daily_planner/services/auth_service.dart' as auth_svc;
import 'dart:io';

// ============================================================================
// OAUTH BUTTONS WIDGET (FIXED - GOOGLE ONLY)
// ============================================================================

/// OAuth button configuration for Google only
class OAuthButtonConfig {
  final auth_svc.OAuthProvider provider;
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;
  final String iconAsset;
  final bool isDark;

  const OAuthButtonConfig({
    required this.provider,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
    required this.iconAsset,
    this.isDark = false,
  });
}

/// FIXED: OAuth buttons widget showing only Google authentication
class OAuthButtons extends StatefulWidget {
  final Function(auth_svc.OAuthResult result)? onResult;
  final bool showAsRow;
  final bool isSignUp;
  final EdgeInsets? padding;
  final double? buttonHeight;
  final bool showPlaceholderNote;

  const OAuthButtons({
    Key? key,
    this.onResult,
    this.showAsRow = false,
    this.isSignUp = false,
    this.padding,
    this.buttonHeight,
    this.showPlaceholderNote = false, // FIXED: Default to false
  }) : super(key: key);

  @override
  State<OAuthButtons> createState() => _OAuthButtonsState();
}

class _OAuthButtonsState extends State<OAuthButtons> {
  final auth_svc.AuthService _authService = auth_svc.AuthService();
  final Set<auth_svc.OAuthProvider> _loadingProviders = {};

  @override
  Widget build(BuildContext context) {
    // FIXED: Only Google OAuth for production
    final availableProviders = [auth_svc.OAuthProvider.google];

    if (availableProviders.isEmpty) {
      return _buildNoProvidersWidget();
    }

    final configs = availableProviders.map(_getProviderConfig).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showPlaceholderNote) _buildPlaceholderNote(),

        widget.showAsRow
            ? _buildButtonsRow(configs)
            : _buildButtonsColumn(configs),

        if (widget.showPlaceholderNote)
          const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildPlaceholderNote() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OAuth Production Mode',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Google OAuth is configured for production use.',
                  style: TextStyle(
                    color: Colors.blue[600],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonsRow(List<OAuthButtonConfig> configs) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: configs.map((config) => _buildCompactButton(config)).toList(),
    );
  }

  Widget _buildButtonsColumn(List<OAuthButtonConfig> configs) {
    return Padding(
      padding: widget.padding ?? EdgeInsets.zero,
      child: Column(
        children: configs
            .map((config) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildFullButton(config),
        ))
            .toList(),
      ),
    );
  }

  Widget _buildFullButton(OAuthButtonConfig config) {
    final isLoading = _loadingProviders.contains(config.provider);

    return SizedBox(
      width: double.infinity,
      height: widget.buttonHeight ?? 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : () => _handleOAuthSignIn(config.provider),
        style: ElevatedButton.styleFrom(
          backgroundColor: config.backgroundColor,
          foregroundColor: config.textColor,
          elevation: 2,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: config.borderColor, width: 1),
          ),
        ),
        child: _buildButtonContent(config, isLoading, false),
      ),
    );
  }

  Widget _buildCompactButton(OAuthButtonConfig config) {
    final isLoading = _loadingProviders.contains(config.provider);
    const double size = 52;

    return SizedBox(
      width: size,
      height: size,
      child: ElevatedButton(
        onPressed: isLoading ? null : () => _handleOAuthSignIn(config.provider),
        style: ElevatedButton.styleFrom(
          backgroundColor: config.backgroundColor,
          foregroundColor: config.textColor,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(size / 4),
            side: BorderSide(color: config.borderColor),
          ),
          padding: EdgeInsets.zero,
        ),
        child: isLoading
            ? SizedBox(
          width: size * 0.4,
          height: size * 0.4,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(config.textColor),
          ),
        )
            : _buildProviderIcon(config.provider, config.textColor, size * 0.5),
      ),
    );
  }

  Widget _buildButtonContent(OAuthButtonConfig config, bool isLoading, bool compact) {
    return Row(
      mainAxisAlignment: compact ? MainAxisAlignment.center : MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(config.textColor),
            ),
          )
        else
          _buildProviderIcon(config.provider, config.textColor, 24),

        if (!isLoading) const SizedBox(width: 12),

        if (!compact)
          Text(
            widget.isSignUp
                ? config.text.replaceFirst('Continue', 'Sign up')
                : config.text,
            style: TextStyle(
              color: config.textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Widget _buildProviderIcon(auth_svc.OAuthProvider provider, Color color, double size) {
    // FIXED: Only Google icon needed
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.asset(
          'assets/images/google_logo.png',
          width: size * 0.7,
          height: size * 0.7,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to icon if image not found
            return Icon(
              Icons.account_circle,
              size: size * 0.8,
              color: Colors.red,
            );
          },
        ),
      ),
    );
  }

  Widget _buildNoProvidersWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.warning, color: Colors.orange[700]),
          const SizedBox(height: 8),
          Text(
            'No OAuth Providers Available',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'OAuth sign-in options are not configured for this platform.',
            style: TextStyle(color: Colors.orange[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _handleOAuthSignIn(auth_svc.OAuthProvider provider) async {
    // Prevent multiple simultaneous requests
    if (_loadingProviders.contains(provider)) return;

    setState(() {
      _loadingProviders.add(provider);
    });

    try {
      // Add haptic feedback
      HapticFeedback.lightImpact();

      // FIXED: Use proper OAuth sign-in method
      final result = await _authService.signInWithOAuth(provider);

      // Show result feedback
      if (result.success) {
        _showSuccessSnackbar(
            'Successfully signed in with Google!'
        );
        HapticFeedback.mediumImpact();
      } else {
        _showErrorSnackbar(result.error ?? 'Google sign-in failed');
        HapticFeedback.heavyImpact();
      }

      // Call result callback
      widget.onResult?.call(result);

    } catch (e) {
      _showErrorSnackbar('Google sign-in error: $e');
      HapticFeedback.heavyImpact();

      widget.onResult?.call(auth_svc.OAuthResult.failure(e.toString()));
    } finally {
      if (mounted) {
        setState(() {
          _loadingProviders.remove(provider);
        });
      }
    }
  }

  void _showSuccessSnackbar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  OAuthButtonConfig _getProviderConfig(auth_svc.OAuthProvider provider) {
    // FIXED: Only Google configuration
    return OAuthButtonConfig(
      provider: provider,
      text: 'Continue with Google',
      backgroundColor: Colors.white,
      textColor: Colors.black87,
      borderColor: Colors.grey[300]!,
      iconAsset: 'assets/images/google_logo.png',
    );
  }
}

// ============================================================================
// OAUTH PROVIDER SELECTION COMPONENTS (GOOGLE ONLY)
// ============================================================================

/// FIXED: OAuth provider selection dialog for Google only
class OAuthProviderDialog extends StatelessWidget {
  final Function(auth_svc.OAuthResult result)? onResult;
  final bool isSignUp;

  const OAuthProviderDialog({
    Key? key,
    this.onResult,
    this.isSignUp = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.login, color: Colors.blue),
          const SizedBox(width: 8),
          Text(isSignUp ? 'Sign Up with Google' : 'Sign In with Google'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isSignUp
                  ? 'Create your account using Google:'
                  : 'Sign in to your account using Google:',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            OAuthButtons(
              onResult: (result) {
                Navigator.of(context).pop();
                onResult?.call(result);
              },
              isSignUp: isSignUp,
              showPlaceholderNote: false,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  /// Show OAuth provider selection dialog
  static Future<void> show(
      BuildContext context, {
        Function(auth_svc.OAuthResult result)? onResult,
        bool isSignUp = false,
      }) {
    return showDialog(
      context: context,
      builder: (context) => OAuthProviderDialog(
        onResult: onResult,
        isSignUp: isSignUp,
      ),
    );
  }
}

/// OAuth configuration widget for settings
class OAuthConfigurationWidget extends StatefulWidget {
  const OAuthConfigurationWidget({Key? key}) : super(key: key);

  @override
  State<OAuthConfigurationWidget> createState() => _OAuthConfigurationWidgetState();
}

class _OAuthConfigurationWidgetState extends State<OAuthConfigurationWidget> {
  final auth_svc.AuthService _authService = auth_svc.AuthService();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.security, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'OAuth Configuration',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Configuration status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Production Ready',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Google OAuth is configured and ready for production use.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Available providers
            const Text(
              'Available Provider (1)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListTile(
              dense: true,
              leading: const Icon(
                Icons.account_circle,
                color: Colors.red,
              ),
              title: const Text('Google'),
              subtitle: const Text('Production ready - Google OAuth 2.0'),
              trailing: const Chip(
                label: Text('Active', style: TextStyle(fontSize: 10)),
                backgroundColor: Colors.green,
                labelStyle: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}