import 'package:calibre_web_companion/features/login_settings/bloc/login_settings_bloc.dart';
import 'package:calibre_web_companion/features/login_settings/bloc/login_settings_event.dart';
import 'package:calibre_web_companion/features/login_settings/presentation/widgets/cloudflare_access_dialog.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum _AddHeaderChoice { plain, cloudflareAccess }

/// Asks what kind of header to add before dropping an empty row into the list —
/// a paired credential such as a Cloudflare service token needs its own form.
class AddHeaderDialog extends StatelessWidget {
  const AddHeaderDialog({super.key});

  static Future<void> show(BuildContext context) async {
    final bloc = context.read<LoginSettingsBloc>();

    final choice = await showDialog<_AddHeaderChoice>(
      context: context,
      builder: (_) => const AddHeaderDialog(),
    );

    switch (choice) {
      case null:
        return;
      case _AddHeaderChoice.plain:
        bloc.add(const AddCustomHeader());
      case _AddHeaderChoice.cloudflareAccess:
        if (!context.mounted) return;
        await CloudflareAccessDialog.show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l.addHeader),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOption(
            context: context,
            icon: Icons.cloud_outlined,
            title: l.cloudflareAccessTitle,
            subtitle: l.cloudflareAccessOptionSubtitle,
            choice: _AddHeaderChoice.cloudflareAccess,
          ),
          _buildOption(
            context: context,
            icon: Icons.code_rounded,
            title: l.addHeaderPlain,
            subtitle: l.addHeaderPlainSubtitle,
            choice: _AddHeaderChoice.plain,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
      ],
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required _AddHeaderChoice choice,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.secondary),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: () => Navigator.of(context).pop(choice),
    );
  }
}
