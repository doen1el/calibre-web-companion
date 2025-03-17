import 'package:calibre_web_companion/view_models/settings_view_mode.dart';
import 'package:calibre_web_companion/views/login_settings.dart';
import 'package:calibre_web_companion/views/widgets/github_issue_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsViewModel = Provider.of<SettingsViewModel>(context);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(localizations.settings)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, localizations.appearance),
            _buildThemeSelector(context, settingsViewModel, localizations),

            const SizedBox(height: 24),
            _buildSectionTitle(context, localizations.connection),
            _buildLoginSettingsCard(context, localizations),

            const SizedBox(height: 24),
            _buildSectionTitle(context, "Calibre Web Automated Downloader"),
            _buildDownloaderToggle(context, settingsViewModel, localizations),

            const SizedBox(height: 24),
            _buildSectionTitle(context, localizations.feedback),
            _buildFeedbackCard(context, localizations, settingsViewModel),

            const SizedBox(height: 24),
            _buildSectionTitle(context, localizations.about),
            _buildVersionCard(context, settingsViewModel),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Builds the feedback card
  ///
  /// Parameters:
  ///
  /// - `context`: The current build context
  /// - `localizations`: The current localizations
  /// - `viewModel`: The settings view model
  Widget _buildFeedbackCard(
    BuildContext context,
    AppLocalizations localizations,
    SettingsViewModel viewModel,
  ) {
    BorderRadius borderRadius = BorderRadius.circular(8.0);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      child: InkWell(
        borderRadius: borderRadius,
        onTap: () {
          final githubToken = const String.fromEnvironment(
            'ISSUE_TOKEN',
            defaultValue: '',
          );

          if (githubToken.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Issue token is not configured'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
            return;
          }

          showDialog(
            context: context,
            builder: (context) {
              return GithubIssueDialog(
                token: const String.fromEnvironment(
                  'ISSUE_TOKEN',
                  defaultValue: '',
                ),
                owner: 'doen1el',
                repo: 'calibre-web-companion',
                initialTitle: "Feature Request/Bug Report",
                initialBody:
                    "## Description\n\n## Expected Behavior\n\n## Current Behavior\n\n## App Version\n${viewModel.appVersion}",
              );
            },
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.bug_report_outlined,
                size: 28,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.reportIssue,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      localizations.reportAppIssueOrSuggestFeature,
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

  Widget _buildLoginSettingsCard(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    BorderRadius borderRadius = BorderRadius.circular(8.0);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      child: InkWell(
        borderRadius: borderRadius,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const LoginSettings()),
          );
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

  Widget _buildDownloaderToggle(
    BuildContext context,
    SettingsViewModel viewModel,
    AppLocalizations localizations,
  ) {
    BorderRadius borderRadius = BorderRadius.circular(8.0);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
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
                  value: viewModel.isDownloaderEnabled,
                  onChanged: (value) => viewModel.toggleDownloader(value),
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),

            // Conditional text field
            if (viewModel.isDownloaderEnabled) ...[
              const SizedBox(height: 16),
              _buildTextField(
                context: context,
                controller: viewModel.downloaderUrlController,
                labelText: localizations.downloadServiceUrl,
                prefixIcon: Icons.link,
                hintText: "https://downloader.example.com",
                onChanged: (value) => viewModel.setDownloaderUrl(value),
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

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String labelText,
    IconData? prefixIcon,
    String? hintText,
    bool obscureText = false,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      onChanged: onChanged,
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

  Widget _buildThemeSelector(
    BuildContext context,
    SettingsViewModel viewModel,
    AppLocalizations localizations,
  ) {
    BorderRadius borderRadius = BorderRadius.circular(8.0);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.dark_mode,
                  size: 28,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    localizations.themeMode,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildThemeOption(
                  context,
                  ThemeMode.system,
                  Icons.brightness_auto,
                  localizations.systemTheme,
                  viewModel,
                ),
                _buildThemeOption(
                  context,
                  ThemeMode.light,
                  Icons.brightness_5,
                  localizations.lightTheme,
                  viewModel,
                ),
                _buildThemeOption(
                  context,
                  ThemeMode.dark,
                  Icons.brightness_2,
                  localizations.darkTheme,
                  viewModel,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    ThemeMode mode,
    IconData icon,
    String label,
    SettingsViewModel viewModel,
  ) {
    final isSelected = viewModel.currentTheme == mode;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => viewModel.setTheme(context, mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? Theme.of(context).colorScheme.secondaryContainer
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color:
                    isSelected
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color:
                      isSelected
                          ? Theme.of(context).colorScheme.secondary
                          : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVersionCard(BuildContext context, SettingsViewModel viewModel) {
    BorderRadius borderRadius = BorderRadius.circular(8.0);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
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
                    'App Version',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    viewModel.appVersion,
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
}
