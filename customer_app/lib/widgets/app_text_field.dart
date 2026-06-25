import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Standard text input for the app: optional uppercase label, theme-driven
/// borders, built-in password show/hide toggle and active-state tinting.
///
/// Wraps a [TextField] — state (controllers, validation, submit) stays with
/// the caller; this only standardises the look and common affordances.
class AppTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final bool obscure;
  final bool active;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final IconData? prefixIcon;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final bool autofocus;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.obscure = false,
    this.active = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.prefixIcon,
    this.maxLines = 1,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.autofocus = false,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget.obscure;

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: widget.controller,
      obscureText: _obscured,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      maxLines: widget.obscure ? 1 : widget.maxLines,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      style: GoogleFonts.inter(fontSize: 13, color: AppTheme.dark),
      decoration: InputDecoration(
        hintText: widget.hint,
        fillColor: widget.active ? AppTheme.primaryTint : AppTheme.inputBg,
        prefixIcon: widget.prefixIcon == null
            ? null
            : Icon(widget.prefixIcon, size: 18, color: AppTheme.hint),
        suffixIcon: widget.obscure
            ? IconButton(
                onPressed: () => setState(() => _obscured = !_obscured),
                icon: Icon(
                  _obscured ? Icons.visibility : Icons.visibility_off,
                  size: 18,
                  color: AppTheme.hint,
                ),
              )
            : null,
        enabledBorder: widget.active
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide:
                    const BorderSide(color: AppTheme.primary, width: 1.5),
              )
            : null,
      ),
    );

    if (widget.label == null) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.label!.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 5),
        field,
      ],
    );
  }
}
