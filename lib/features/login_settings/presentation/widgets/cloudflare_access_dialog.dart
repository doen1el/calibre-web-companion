import 'package:calibre_web_companion/core/utils/http_header_utils.dart';
import 'package:calibre_web_companion/features/login_settings/bloc/login_settings_bloc.dart';
import 'package:calibre_web_companion/features/login_settings/bloc/login_settings_event.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/shared/widgets/app_dialog_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CloudflareAccessDialog extends StatefulWidget {
  final String initialClientId;
  final String initialClientSecret;

  const CloudflareAccessDialog({
    super.key,
    this.initialClientId = '',
    this.initialClientSecret = '',
  });

  static Future<void> show(BuildContext context) async {
    final bloc = context.read<LoginSettingsBloc>();
    final state = bloc.state;

    String valueFor(String headerName) {
      for (final header in state.customHeaders) {
        if (sanitizeHeaderName(header.key).toLowerCase() ==
            headerName.toLowerCase()) {
          return header.value;
        }
      }
      return '';
    }

    await showDialog<void>(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: bloc,
            child: CloudflareAccessDialog(
              initialClientId: valueFor(cfAccessClientIdHeader),
              initialClientSecret: valueFor(cfAccessClientSecretHeader),
            ),
          ),
    );
  }

  @override
  State<CloudflareAccessDialog> createState() => _CloudflareAccessDialogState();
}

class _CloudflareAccessDialogState extends State<CloudflareAccessDialog> {
  late final TextEditingController _clientIdController;
  late final TextEditingController _clientSecretController;
  bool _obscureSecret = true;

  @override
  void initState() {
    super.initState();
    _clientIdController = TextEditingController(text: widget.initialClientId);
    _clientSecretController = TextEditingController(
      text: widget.initialClientSecret,
    );
  }

  @override
  void dispose() {
    _clientIdController.dispose();
    _clientSecretController.dispose();
    super.dispose();
  }

  String get _clientId => sanitizeHeaderValue(_clientIdController.text);
  String get _clientSecret => sanitizeHeaderValue(_clientSecretController.text);

  bool get _canSave => _clientId.isNotEmpty && _clientSecret.isNotEmpty;

  void _save() {
    context.read<LoginSettingsBloc>().add(
      ApplyCloudflareAccessToken(
        clientId: _clientId,
        clientSecret: _clientSecret,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    final idLooksWrong = _clientId.isNotEmpty && !_clientId.endsWith('.access');

    return AlertDialog(
      title: Text(l.cloudflareAccessTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.cloudflareAccessDescription,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _clientIdController,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.none,
              style: const TextStyle(fontFamily: 'monospace'),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l.cloudflareAccessClientId,
                hintText: 'xxxxxxxx.access',
                helperText: idLooksWrong ? l.cloudflareAccessIdHint : null,
                helperMaxLines: 3,
                helperStyle: TextStyle(color: scheme.error),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _clientSecretController,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.none,
              obscureText: _obscureSecret,
              style: const TextStyle(fontFamily: 'monospace'),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l.cloudflareAccessClientSecret,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureSecret
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
                  onPressed:
                      () => setState(() => _obscureSecret = !_obscureSecret),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        AppDialogButton(label: l.save, onPressed: _canSave ? _save : null),
      ],
    );
  }
}
