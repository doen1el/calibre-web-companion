import 'package:flutter/material.dart';

class CostumTextField extends StatelessWidget {
  final BuildContext context;
  final TextEditingController controller;
  final String labelText;
  final IconData? prefixIcon;
  final String? hintText;
  final bool obscureText;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;

  const CostumTextField({
    super.key,
    required this.context,
    required this.controller,
    required this.labelText,
    this.prefixIcon,
    this.hintText,
    this.obscureText = false,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 14.0,
        ),
      ),
    );
  }
}
