import 'package:calibre_web_companion/core/utils/http_header_utils.dart';
import 'package:calibre_web_companion/features/login_settings/bloc/login_settings_bloc.dart';
import 'package:calibre_web_companion/features/login_settings/bloc/login_settings_event.dart';
import 'package:calibre_web_companion/features/login_settings/data/models/custom_header.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HeaderItem extends StatelessWidget {
  final int index;
  final CustomHeaderModel header;
  final bool isLast;
  final bool isDuplicate;

  const HeaderItem({
    super.key,
    required this.index,
    required this.header,
    required this.isLast,
    this.isDuplicate = false,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${localizations.header} ${index + 1}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(
                Icons.delete,
                color: Theme.of(context).colorScheme.error,
                size: 20,
              ),
              onPressed: () {
                context.read<LoginSettingsBloc>().add(
                  DeleteCustomHeader(index),
                );
              },
              tooltip: localizations.deleteHeader,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minHeight: 36, minWidth: 36),
            ),
          ],
        ),
        const SizedBox(height: 8),

        _buildTextField(
          context: context,
          initialValue: header.key,
          labelText: localizations.headerKey,
          errorText: _nameError(localizations),
          onChanged: (newKey) {
            context.read<LoginSettingsBloc>().add(
              UpdateCustomHeaderKey(index, newKey),
            );
          },
        ),

        const SizedBox(height: 12),

        _buildTextField(
          context: context,
          initialValue: header.value,
          labelText: localizations.headerValue,
          errorText: _valueError(localizations),
          onChanged: (newValue) {
            context.read<LoginSettingsBloc>().add(
              UpdateCustomHeaderValue(index, newValue),
            );
          },
        ),

        if (!isLast)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Theme.of(context).colorScheme.outlineVariant),
          )
        else
          const SizedBox(height: 8),
      ],
    );
  }

  String? _nameError(AppLocalizations l) {
    final issue = inspectHeaderName(header.key, isDuplicate: isDuplicate);
    switch (issue) {
      case null:
        return null;
      case HeaderNameIssue.empty:
        return header.value.trim().isEmpty ? null : l.headerIssueEmptyName;
      case HeaderNameIssue.invalidCharacters:
        return l.headerIssueInvalidName;
      case HeaderNameIssue.duplicate:
        return l.headerIssueDuplicateName;
    }
  }

  String? _valueError(AppLocalizations l) {
    final issue = inspectHeaderValue(header.value, name: header.key);
    switch (issue) {
      case null:
        return null;
      case HeaderValueIssue.empty:
        return header.key.trim().isEmpty ? null : l.headerIssueEmptyValue;
      case HeaderValueIssue.invalidCharacters:
        return l.headerIssueInvalidValue;
      case HeaderValueIssue.looksLikeHeaderName:
        return l.headerIssueValueIsHeaderName;
    }
  }

  Widget _buildTextField({
    required BuildContext context,
    String? initialValue,
    required String labelText,
    IconData? prefixIcon,
    String? hintText,
    String? errorText,
    bool obscureText = false,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      initialValue: initialValue,
      obscureText: obscureText,
      onChanged: onChanged,
      autocorrect: false,
      enableSuggestions: false,
      textCapitalization: TextCapitalization.none,
      style: const TextStyle(fontFamily: 'monospace'),
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        labelText: labelText,
        hintText: hintText,
        errorText: errorText,
        errorMaxLines: 4,
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
