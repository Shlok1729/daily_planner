import 'package:flutter/material.dart';
import 'package:daily_planner/utils/auth_utils.dart';

// ============================================================================
// PASSWORD FIELD WITH STRENGTH INDICATOR (FIXED - RESOLVED CONFLICTS)
// ============================================================================

/// Password field widget with strength indicator and validation
/// FIXED: Resolved naming conflicts and added proper functionality
class PasswordFieldWithStrength extends StatefulWidget {
  final TextEditingController controller;
  final String? label;
  final String? hintText; // FIXED: Added hintText parameter
  final bool showStrengthIndicator;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
  final EdgeInsets? contentPadding;
  final double borderRadius;
  final Color? fillColor;
  final Color? borderColor;
  final Color? focusedBorderColor;

  const PasswordFieldWithStrength({
    Key? key,
    required this.controller,
    this.label,
    this.hintText, // FIXED: Added hintText parameter
    this.showStrengthIndicator = true,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.contentPadding,
    this.borderRadius = 8.0,
    this.fillColor,
    this.borderColor,
    this.focusedBorderColor,
  }) : super(key: key);

  @override
  State<PasswordFieldWithStrength> createState() => _PasswordFieldWithStrengthState();
}

class _PasswordFieldWithStrengthState extends State<PasswordFieldWithStrength> {
  bool _obscureText = true;
  String _password = '';
  int _strengthScore = 0;
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
    _password = widget.controller.text;
    _updateStrength();
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _updateStrength() {
    setState(() {
      _strengthScore = AuthUtils.getPasswordStrength(_password);
    });
  }

  void _toggleObscureText() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  void _onPasswordChanged(String value) {
    _password = value;
    _updateStrength();
    widget.onChanged?.call(value);
  }

  Color _getStrengthColor() {
    switch (_strengthScore) {
      case 0:
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow[700]!;
      case 4:
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStrengthText() {
    return AuthUtils.getPasswordStrengthText(_password);
  }

  double _getStrengthProgress() {
    return _strengthScore / 5.0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: _isFocused
                  ? widget.focusedBorderColor ?? colorScheme.primary
                  : theme.textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          obscureText: _obscureText,
          keyboardType: TextInputType.visiblePassword,
          textInputAction: TextInputAction.done,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          onChanged: _onPasswordChanged,
          onFieldSubmitted: widget.onSubmitted,
          validator: widget.validator,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: widget.hintText ?? 'Enter your password',
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
            ),
            prefixIcon: Icon(
              Icons.lock_outline,
              color: _isFocused
                  ? widget.focusedBorderColor ?? colorScheme.primary
                  : theme.iconTheme.color?.withOpacity(0.7),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility_off : Icons.visibility,
                color: theme.iconTheme.color?.withOpacity(0.7),
              ),
              onPressed: _toggleObscureText,
              tooltip: _obscureText ? 'Show password' : 'Hide password',
            ),
            filled: true,
            fillColor: widget.fillColor ??
                (theme.brightness == Brightness.dark
                    ? colorScheme.surface
                    : colorScheme.surface.withOpacity(0.5)),
            contentPadding: widget.contentPadding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              borderSide: BorderSide(
                color: widget.borderColor ??
                    theme.colorScheme.outline.withOpacity(0.5),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              borderSide: BorderSide(
                color: widget.borderColor ??
                    theme.colorScheme.outline.withOpacity(0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              borderSide: BorderSide(
                color: widget.focusedBorderColor ?? colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              borderSide: BorderSide(
                color: colorScheme.error,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              borderSide: BorderSide(
                color: colorScheme.error,
                width: 2,
              ),
            ),
          ),
        ),

        // Password strength indicator
        if (widget.showStrengthIndicator && _password.isNotEmpty) ...[
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: _getStrengthProgress(),
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getStrengthColor(),
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _getStrengthText(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _getStrengthColor(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildPasswordRequirements(),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPasswordRequirements() {
    final theme = Theme.of(context);

    final requirements = [
      {
        'text': 'At least 8 characters',
        'met': _password.length >= 8,
      },
      {
        'text': 'Contains uppercase letter',
        'met': _password.contains(RegExp(r'[A-Z]')),
      },
      {
        'text': 'Contains lowercase letter',
        'met': _password.contains(RegExp(r'[a-z]')),
      },
      {
        'text': 'Contains number',
        'met': _password.contains(RegExp(r'[0-9]')),
      },
      {
        'text': 'Contains special character',
        'met': _password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: requirements.map((req) {
        final isMet = req['met'] as bool;
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Icon(
                isMet ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 16,
                color: isMet ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  req['text'] as String,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isMet ? Colors.green : Colors.grey,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ============================================================================
// PASSWORD STRENGTH UTILITIES
// ============================================================================

/// Utility class for password strength evaluation
class PasswordStrengthUtils {
  /// Calculate password strength score (0-5)
  static int calculateStrength(String password) {
    int score = 0;

    // Length checks
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;

    // Character type checks
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;

    return score.clamp(0, 5);
  }

  /// Get password strength description
  static String getStrengthDescription(int score) {
    switch (score) {
      case 0:
      case 1:
        return 'Very Weak';
      case 2:
        return 'Weak';
      case 3:
        return 'Fair';
      case 4:
        return 'Good';
      case 5:
        return 'Strong';
      default:
        return 'Very Weak';
    }
  }

  /// Get password strength color
  static Color getStrengthColor(int score) {
    switch (score) {
      case 0:
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow[700]!;
      case 4:
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// Check if password meets minimum requirements
  static bool meetsMinimumRequirements(String password) {
    return password.length >= 8 &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[0-9]'));
  }

  /// Get list of unmet requirements
  static List<String> getUnmetRequirements(String password) {
    final unmet = <String>[];

    if (password.length < 8) {
      unmet.add('At least 8 characters');
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      unmet.add('Contains uppercase letter');
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      unmet.add('Contains lowercase letter');
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      unmet.add('Contains number');
    }
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      unmet.add('Contains special character');
    }

    return unmet;
  }

  /// Generate password strength feedback
  static String generateFeedback(String password) {
    final score = calculateStrength(password);
    final unmet = getUnmetRequirements(password);

    if (score >= 4) {
      return 'Great! Your password is ${getStrengthDescription(score).toLowerCase()}.';
    } else if (score >= 3) {
      return 'Good progress! Consider adding ${unmet.isNotEmpty ? unmet.first.toLowerCase() : 'more complexity'}.';
    } else if (score >= 2) {
      return 'Getting better! Your password needs: ${unmet.join(', ').toLowerCase()}.';
    } else {
      return 'Weak password. Please include: ${unmet.join(', ').toLowerCase()}.';
    }
  }
}