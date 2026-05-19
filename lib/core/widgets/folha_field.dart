import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/folha_colors.dart';
import '../theme/folha_tokens.dart';
import '../theme/folha_typography.dart';

class FolhaField extends StatelessWidget {
  final String label;
  final Widget child;
  final String? hint;
  final String? error;
  final String? trailLinkLabel;
  final VoidCallback? onTrailLinkTap;

  const FolhaField({
    super.key,
    required this.label,
    required this.child,
    this.hint,
    this.error,
    this.trailLinkLabel,
    this.onTrailLinkTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: FolhaTypography.eyebrow.copyWith(
                    letterSpacing: 0.66,
                  ),
                ),
              ),
              if (trailLinkLabel != null)
                GestureDetector(
                  onTap: onTrailLinkTap,
                  child: Text(
                    trailLinkLabel!,
                    style: FolhaTypography.body.copyWith(
                      fontSize: 12,
                      color: FolhaColors.forest700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
        child,
        if (hint != null && error == null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              hint!,
              style: FolhaTypography.bodySm.copyWith(fontSize: 12),
            ),
          ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              error!,
              style: FolhaTypography.bodySm.copyWith(
                fontSize: 12,
                color: FolhaColors.terra700,
              ),
            ),
          ),
      ],
    );
  }
}

/// Input padrão Folha — borda hairline, fundo paper-50.
class FolhaInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;
  final TextInputAction? textInputAction;
  final bool autofocus;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final TextAlign textAlign;

  const FolhaInput({
    super.key,
    this.controller,
    this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.onChanged,
    this.suffix,
    this.textInputAction,
    this.autofocus = false,
    this.inputFormatters,
    this.maxLength,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: onChanged,
      textInputAction: textInputAction,
      autofocus: autofocus,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      textAlign: textAlign,
      style: FolhaTypography.body,
      cursorColor: FolhaColors.forest700,
      decoration: InputDecoration(
        counterText: '',
        hintText: hintText,
        hintStyle: FolhaTypography.body.copyWith(color: FolhaColors.ink300),
        filled: true,
        fillColor: FolhaColors.paper50,
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FolhaRadius.md),
          borderSide: const BorderSide(color: FolhaColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FolhaRadius.md),
          borderSide: const BorderSide(color: FolhaColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FolhaRadius.md),
          borderSide: const BorderSide(color: FolhaColors.forest700),
        ),
      ),
    );
  }
}
