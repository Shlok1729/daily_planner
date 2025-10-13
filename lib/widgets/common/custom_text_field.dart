import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================================================
// CUSTOM TEXT FIELD WIDGET (FIXED - ADDED MISSING PARAMETERS)
// ============================================================================

/// Custom text field widget with enhanced styling and functionality
/// FIXED: Added missing hintText parameter and other required parameters
class CustomTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hintText; // FIXED: Added missing hintText parameter
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final void Function()? onTap;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final bool autofocus;
  final Color? fillColor;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final double borderRadius;
  final EdgeInsets? contentPadding;
  final TextStyle? textStyle;
  final TextStyle? labelStyle;
  final TextStyle? hintStyle;
  final bool filled;
  final bool isDense;
  final String? helperText;
  final String? errorText;
  final int? errorMaxLines;

  const CustomTextField({
    Key? key,
    this.controller,
    this.label,
    this.hintText, // FIXED: Added hintText parameter
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.inputFormatters,
    this.focusNode,
    this.autofocus = false,
    this.fillColor,
    this.borderColor,
    this.focusedBorderColor,
    this.borderRadius = 8.0,
    this.contentPadding,
    this.textStyle,
    this.labelStyle,
    this.hintStyle,
    this.filled = true,
    this.isDense = false,
    this.helperText,
    this.errorText,
    this.errorMaxLines,
  }) : super(key: key);

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
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
            style: widget.labelStyle ??
                theme.textTheme.bodyMedium?.copyWith(
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
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          onTap: widget.onTap,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          maxLength: widget.maxLength,
          inputFormatters: widget.inputFormatters,
          autofocus: widget.autofocus,
          style: widget.textStyle ?? theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: widget.hintText, // FIXED: Using hintText parameter
            hintStyle: widget.hintStyle ??
                theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                ),
            prefixIcon: widget.prefixIcon != null
                ? Icon(
              widget.prefixIcon,
              color: _isFocused
                  ? widget.focusedBorderColor ?? colorScheme.primary
                  : theme.iconTheme.color?.withOpacity(0.7),
            )
                : null,
            suffixIcon: widget.suffixIcon,
            filled: widget.filled,
            fillColor: widget.fillColor ??
                (theme.brightness == Brightness.dark
                    ? colorScheme.surface
                    : colorScheme.surface.withOpacity(0.5)),
            contentPadding: widget.contentPadding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            isDense: widget.isDense,
            helperText: widget.helperText,
            errorText: widget.errorText,
            errorMaxLines: widget.errorMaxLines,
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
      ],
    );
  }
}

// ============================================================================
// CUSTOM BUTTON WIDGET (FIXED - RESOLVED CONFLICTS)
// ============================================================================

/// Custom button widget with enhanced styling and loading states
/// FIXED: Resolved naming conflicts and added proper functionality
class CustomButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final bool isEnabled;
  final ButtonStyle? style;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? disabledBackgroundColor;
  final Color? disabledForegroundColor;
  final EdgeInsets? padding;
  final double? borderRadius;
  final double? elevation;
  final Size? minimumSize;
  final Size? maximumSize;
  final BorderSide? side;
  final bool autofocus;
  final FocusNode? focusNode;
  final String? tooltip;
  final Duration? animationDuration;

  const CustomButton({
    Key? key,
    this.onPressed,
    required this.child,
    this.isLoading = false,
    this.isEnabled = true,
    this.style,
    this.backgroundColor,
    this.foregroundColor,
    this.disabledBackgroundColor,
    this.disabledForegroundColor,
    this.padding,
    this.borderRadius,
    this.elevation,
    this.minimumSize,
    this.maximumSize,
    this.side,
    this.autofocus = false,
    this.focusNode,
    this.tooltip,
    this.animationDuration,
  }) : super(key: key);

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration ?? const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.isEnabled && !widget.isLoading) {
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.isEnabled && !widget.isLoading) {
      _animationController.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.isEnabled && !widget.isLoading) {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isDisabled = !widget.isEnabled || widget.isLoading;

    Widget button = ElevatedButton(
      onPressed: isDisabled ? null : widget.onPressed,
      style: widget.style ??
          ElevatedButton.styleFrom(
            backgroundColor: widget.backgroundColor ?? colorScheme.primary,
            foregroundColor: widget.foregroundColor ?? colorScheme.onPrimary,
            disabledBackgroundColor: widget.disabledBackgroundColor ??
                colorScheme.onSurface.withOpacity(0.12),
            disabledForegroundColor: widget.disabledForegroundColor ??
                colorScheme.onSurface.withOpacity(0.38),
            padding: widget.padding ??
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius ?? 8),
              side: widget.side ?? BorderSide.none,
            ),
            elevation: widget.elevation ?? 2,
            minimumSize: widget.minimumSize ?? const Size(88, 44),
            maximumSize: widget.maximumSize,
          ),
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      child: widget.isLoading
          ? SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            widget.foregroundColor ?? colorScheme.onPrimary,
          ),
        ),
      )
          : widget.child,
    );

    // Add tap animation
    button = GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: button,
          );
        },
      ),
    );

    // Add tooltip if provided
    if (widget.tooltip != null) {
      button = Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }

    return button;
  }
}

// ============================================================================
// UTILITY EXTENSIONS
// ============================================================================

/// Extension for common text field validations
extension TextFieldValidation on String {
  bool get isValidEmail {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(this);
  }

  bool get isValidPassword {
    return length >= 8 &&
        contains(RegExp(r'[A-Z]')) &&
        contains(RegExp(r'[a-z]')) &&
        contains(RegExp(r'[0-9]'));
  }

  // FIXED: Proper regex for phone number validation
  bool get isValidPhoneNumber {
    return RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(this);
  }

  bool get isValidName {
    return trim().isNotEmpty && length >= 2 && length <= 50;
  }
}

/// Extension for text field formatters
extension TextFieldFormatters on List<TextInputFormatter> {
  static List<TextInputFormatter> get phoneNumber => [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(15),
  ];

  static List<TextInputFormatter> get email => [
    FilteringTextInputFormatter.deny(RegExp(r'\s')),
    LengthLimitingTextInputFormatter(100),
  ];

  static List<TextInputFormatter> get name => [
    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
    LengthLimitingTextInputFormatter(50),
  ];

  static List<TextInputFormatter> get currency => [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
    LengthLimitingTextInputFormatter(10),
  ];
}