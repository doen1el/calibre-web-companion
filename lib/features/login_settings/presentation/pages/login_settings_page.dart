import 'package:calibre_web_companion/shared/widgets/coming_soon_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';

import 'package:calibre_web_companion/features/login_settings/bloc/login_settings_bloc.dart';
import 'package:calibre_web_companion/features/login_settings/bloc/login_settings_event.dart';
import 'package:calibre_web_companion/features/login_settings/bloc/login_settings_state.dart';

import 'package:calibre_web_companion/core/services/snackbar.dart';
import 'package:calibre_web_companion/features/login_settings/presentation/widgets/header_section_widget.dart';

class LoginSettingsPage extends StatefulWidget {
  const LoginSettingsPage({super.key});

  @override
  State<LoginSettingsPage> createState() => _LoginSettingsPage();
}

class _LoginSettingsPage extends State<LoginSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocConsumer<LoginSettingsBloc, LoginSettingsState>(
      listener: (context, state) {
        if (state.isSaved) {
          context.showSnackBar(localizations.settingsSaved);
        }

        if (state.errorMessage != null) {
          context.showSnackBar(state.errorMessage!, isError: true);
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(localizations.connectionSettings),
            actions: [
              IconButton(
                icon: const Icon(Icons.save),
                tooltip: localizations.save,
                onPressed: () {
                  context.read<LoginSettingsBloc>().add(
                    const SaveLoginSettings(),
                  );
                },
              ),
            ],
          ),
          body:
              state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle(
                          context,
                          localizations.basePathTitle,
                        ),
                        _buildBasePathSection(context, state, localizations),

                        _buildSectionTitle(context, localizations.sslSettings),
                        _buildSSLSettingsSection(context, localizations),

                        _buildSectionTitle(
                          context,
                          localizations.costumHttpPHeader,
                        ),
                        const HeadersSection(),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 16.0,
                          ),
                          child: Center(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                context.read<LoginSettingsBloc>().add(
                                  const AddCustomHeader(),
                                );
                              },
                              icon: const Icon(Icons.add),
                              label: Text(localizations.addHeader),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                                foregroundColor:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
        );
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }

  Widget _buildSSLSettingsSection(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.security_rounded,
                  size: 28,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.sslCertificate,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        localizations.settingsForSSL,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: Text(localizations.allowSelfSignedCertificates),
              value: false,
              onChanged: (_) {
                // TODO: Implement self-signed certificate handling
                showComingSoonDialog(
                  context,
                  "The feature to allow self-signed certificates is coming soon!",
                );
              },
              dense: false,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasePathSection(
    BuildContext context,
    LoginSettingsState state,
    AppLocalizations localizations,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.link_rounded,
                  size: 28,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.basePathTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        localizations.basePathDescription,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              initialValue: state.basePath,
              onChanged: (value) {
                context.read<LoginSettingsBloc>().add(UpdateBasePath(value));
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                labelText: localizations.basePathLabel,
                hintText: localizations.basePathHint,
                prefixIcon: const Icon(Icons.folder_outlined),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 14.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
