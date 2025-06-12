import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:calibre_web_companion/features/settings/bloc/settings_bloc.dart';
import 'package:calibre_web_companion/features/settings/bloc/settings_event.dart';
import 'package:calibre_web_companion/features/settings/bloc/settings_state.dart';

import 'package:calibre_web_companion/core/services/snackbar.dart';
import 'package:calibre_web_companion/core/services/app_transition.dart';
import 'package:calibre_web_companion/features/login_settings/presentation/pages/login_settings_page.dart';
import 'package:calibre_web_companion/features/settings/presentation/widgets/download_options_widget.dart';
import 'package:calibre_web_companion/features/settings/presentation/widgets/feedback_widget.dart';
import 'package:calibre_web_companion/features/settings/presentation/widgets/theme_selector_widget.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocConsumer<SettingsBloc, SettingsState>(
      listener: (context, state) {
        if (state.status == SettingsStatus.error) {
          context.showSnackBar(
            state.errorMessage ?? localizations.unknownError,
            isError: true,
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: Text(localizations.settings)),
          body:
              state.status == SettingsStatus.loading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle(context, localizations.appearance),
                        const ThemeSelectorWidget(),

                        const SizedBox(height: 24),
                        _buildSectionTitle(context, localizations.connection),
                        _buildLoginSettingsCard(context, localizations),

                        const SizedBox(height: 24),
                        _buildSectionTitle(context, localizations.language),
                        _buildLanguageSelector(context, state, localizations),

                        const SizedBox(height: 24),
                        _buildSectionTitle(context, "Download Options"),
                        const DownloadOptionsWidget(),

                        const SizedBox(height: 24),
                        _buildSectionTitle(context, "Custom send2ereader"),
                        _buildSend2EreaderToggle(context, state, localizations),

                        const SizedBox(height: 24),
                        _buildSectionTitle(
                          context,
                          "Calibre Web Automated Downloader",
                        ),
                        _buildDownloaderToggle(context, state, localizations),

                        const SizedBox(height: 24),
                        _buildSectionTitle(context, localizations.feedback),
                        const FeedbackWidget(),

                        const SizedBox(height: 24),
                        _buildSectionTitle(context, localizations.about),
                        _buildVersionCard(context, state, localizations),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
        );
      },
    );
  }

  // Login Settings Card
  Widget _buildLoginSettingsCard(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8.0),
        onTap: () {
          Navigator.of(
            context,
          ).push(AppTransitions.createSlideRoute(LoginSettingsPage()));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.vpn_key_rounded,
                size: 28,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.connectionSettings,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      localizations.httpHeaderSettings,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Section Title
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

  // Downloader Toggle
  Widget _buildDownloaderToggle(
    BuildContext context,
    SettingsState state,
    AppLocalizations localizations,
  ) {
    final TextEditingController urlController = TextEditingController(
      text: state.downloaderUrl,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.download_rounded,
                  size: 28,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    localizations.downloadService,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Switch(
                  value: state.isDownloaderEnabled,
                  onChanged:
                      (value) => context.read<SettingsBloc>().add(
                        SetDownloaderEnabled(value),
                      ),
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),

            // Conditional text field
            if (state.isDownloaderEnabled) ...[
              const SizedBox(height: 16),
              TextField(
                controller: urlController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  labelText: localizations.downloadServiceUrl,
                  hintText: "https://downloader.example.com",
                  prefixIcon: const Icon(Icons.link),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 14.0,
                  ),
                ),
                onChanged:
                    (value) => context.read<SettingsBloc>().add(
                      SetDownloaderUrl(value),
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                localizations.enterUrlOfYourDownloadService,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Send2EReader Toggle
  Widget _buildSend2EreaderToggle(
    BuildContext context,
    SettingsState state,
    AppLocalizations localizations,
  ) {
    final TextEditingController urlController = TextEditingController(
      text: state.send2ereaderUrl,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.send_rounded,
                  size: 28,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    localizations.send2ereaderService,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Switch(
                  value: state.isSend2ereaderEnabled,
                  onChanged:
                      (value) => context.read<SettingsBloc>().add(
                        SetCostumSend2EreaderEnabled(value),
                      ),
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),

            // Conditional text field
            if (state.isSend2ereaderEnabled) ...[
              const SizedBox(height: 16),
              TextField(
                controller: urlController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  labelText: localizations.send2ereaderServiceUrl,
                  hintText: "https://send.djazz.se/",
                  prefixIcon: const Icon(Icons.link),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 14.0,
                  ),
                ),
                onChanged:
                    (value) => context.read<SettingsBloc>().add(
                      SetCostumSend2EreaderUrl(value),
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                localizations.enterUrlOfYourSend2ereaderService,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Version Card
  Widget _buildVersionCard(
    BuildContext context,
    SettingsState state,
    AppLocalizations localizations,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 28,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.appVersion,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${state.appVersion ?? 'unknown'} (${state.buildNumber ?? 'dev'})",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(
    BuildContext context,
    SettingsState state,
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
                  Icons.language,
                  size: 28,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    localizations.language,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8.0,
              children: [
                _buildLanguageOption(context, 'en', 'English', state),
                _buildLanguageOption(context, 'de', 'Deutsch', state),
                _buildLanguageOption(context, 'fr', 'Français', state),
                _buildLanguageOption(context, 'es', 'Español', state),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    String code,
    String name,
    SettingsState state,
  ) {
    final isSelected = state.languageCode == code;

    return ChoiceChip(
      label: Text(name),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          context.read<SettingsBloc>().add(SetLanguage(code));
        }
      },
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
    );
  }
}
