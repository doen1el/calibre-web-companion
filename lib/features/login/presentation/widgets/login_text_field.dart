import 'package:flutter/material.dart';

class LoginTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final bool obscureText;
  final String? autofillHint;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const LoginTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.prefixIcon,
    this.obscureText = false,
    this.autofillHint,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final ValueNotifier<bool> isObscureTextNotifier = ValueNotifier<bool>(
      obscureText,
    );

    return ValueListenableBuilder<bool>(
      valueListenable: isObscureTextNotifier,
      builder: (context, isObscureText, _) {
        return TextField(
          controller: controller,
          autofillHints: autofillHint != null ? [autofillHint!] : null,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          onChanged: onChanged,
          obscureText: isObscureText,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            labelText: labelText,
            hintText: hintText,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
            suffixIcon:
                obscureText
                    ? IconButton(
                      icon: Icon(
                        isObscureText ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        isObscureTextNotifier.value = !isObscureText;
                      },
                    )
                    : null,
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 14.0,
            ),
          ),
        );
      },
    );
  }
}
