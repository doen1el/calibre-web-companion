import 'dart:io';

import 'package:calibre_web_companion/utils/app_transition.dart';
import 'package:calibre_web_companion/utils/snack_bar.dart';
import 'package:calibre_web_companion/view_models/settings_view_mode.dart';
import 'package:calibre_web_companion/views/login_settings.dart';
import 'package:calibre_web_companion/views/widgets/github_issue_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
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
            _buildColorThemeSelector(context, settingsViewModel, localizations),

            const SizedBox(height: 24),
            _buildSectionTitle(context, localizations.connection),
            _buildLoginSettingsCard(context, localizations),

            const SizedBox(height: 24),
            _buildSectionTitle(context, "Download Options"),
            _buildSelectingDownloadFolder(
              context,
              settingsViewModel,
              localizations,
            ),
            _buildSelectingDownloadSchema(
              context,
              settingsViewModel,
              localizations,
            ),

            const SizedBox(height: 24),
            _buildSectionTitle(context, "Calibre Web Automated Downloader"),
            _buildDownloaderToggle(context, settingsViewModel, localizations),

            const SizedBox(height: 24),
            _buildSectionTitle(context, localizations.feedback),
            _buildFeedbackCard(context, localizations, settingsViewModel),

            const SizedBox(height: 24),
            _buildSectionTitle(context, localizations.about),
            _buildVersionCard(context, settingsViewModel, localizations),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Builds the selecting download folder card
  ///
  /// Parameters:
  ///
  /// - `context`: The current build context
  /// - `settingsViewModel`: The settings view model
  /// - `localizations`: The current localizations
  _buildSelectingDownloadFolder(
    BuildContext context,
    SettingsViewModel settingsViewModel,
    AppLocalizations localizations,
  ) {
    BorderRadius borderRadius = BorderRadius.circular(8.0);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.downloadFolder,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    settingsViewModel.defaultDownloadPath.isNotEmpty
                        ? settingsViewModel.defaultDownloadPath
                        : localizations.noFolderSelected,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () async {
                if (!await checkAndRequestPermissions()) {
                  // ignore: use_build_context_synchronously
                  context.showSnackBar(
                    localizations.storagePermissionRequiredToSelectAFolder,
                    isError: true,
                  );
                  return;
                }

                String? selectedDirectory =
                    await FilePicker.platform.getDirectoryPath();
                if (selectedDirectory == null) {
                  // ignore: use_build_context_synchronously
                  context.showSnackBar(
                    localizations.noFolderWasSelected,
                    isError: true,
                  );
                  return;
                }
                await settingsViewModel.setDefaultDownloadPath(
                  selectedDirectory,
                );

                // ignore: use_build_context_synchronously
                context.showSnackBar(
                  localizations.folderSelectedSuccessfully,
                  isError: false,
                );
              },
              child: Text(localizations.select),
            ),
          ],
        ),
      ),
    );
  }

  /// Check and request storage permissions
  Future<bool> checkAndRequestPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        final result = await Permission.manageExternalStorage.request();
        return result.isGranted;
      } else if (status.isPermanentlyDenied) {
        await openAppSettings();
      }
      return true;
    }
    return true;
  }

  /// Builds the selecting download schema card
  ///
  /// Parameters:
  ///
  /// - `context`: The current build context
  /// - `settingsViewModel`: The settings view model
  /// - `localizations`: The current localizations
  _buildSelectingDownloadSchema(
    BuildContext context,
    SettingsViewModel settingsViewModel,
    AppLocalizations localizations,
  ) {
    BorderRadius borderRadius = BorderRadius.circular(8.0);

    final schemaInfo = _getSchemaDisplayInfo(
      settingsViewModel.downloadSchema,
      localizations,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.downloadSchema,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    schemaInfo['title'] ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    schemaInfo['example'] ?? '',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () async {
                _showSchemaSelectionDialog(context, localizations).then((
                  value,
                ) async {
                  if (value != null) {
                    await settingsViewModel.setDownloadSchema(value);

                    // ignore: use_build_context_synchronously
                    context.showSnackBar(
                      localizations.schemaWasSelectedSuccessfully,
                      isError: false,
                    );
                  }
                });
              },
              child: Text(localizations.select),
            ),
          ],
        ),
      ),
    );
  }

  /// Get the schema display information
  ///
  /// Parameters:
  ///
  /// - `schema`: The schema to get information for
  /// - `localizations`: The current localizations
  Map<String, String> _getSchemaDisplayInfo(
    DownloadSchema schema,
    AppLocalizations localizations,
  ) {
    switch (schema) {
      case DownloadSchema.flat:
        return {'title': localizations.schemaFlat, 'example': '/book1.epub'};
      case DownloadSchema.authorOnly:
        return {
          'title': localizations.schemaAuthorOnly,
          'example': '/author/book1.epub',
        };
      case DownloadSchema.authorBook:
        return {
          'title': localizations.schemaAuthorBook,
          'example': '/author/book1/book1.epub',
        };
      case DownloadSchema.authorSeriesBook:
        return {
          'title': localizations.schemaAuthorSeriesBook,
          'example': '/author/series/book1/book1.epub',
        };
    }
  }

  /// Show the schema selection dialog
  ///
  /// Parameters:
  ///
  /// - `context`: The current build context
  /// - `localizations`: The app localizations
  Future<DownloadSchema?> _showSchemaSelectionDialog(
    BuildContext context,
    AppLocalizations localizations,
  ) async {
    return showDialog<DownloadSchema>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(localizations.selectDownloadSchema),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSchemaOption(
                  context,
                  DownloadSchema.flat,
                  localizations.schemaFlat,
                  '/book1.epub',
                ),
                _buildSchemaOption(
                  context,
                  DownloadSchema.authorOnly,
                  localizations.schemaAuthorOnly,
                  '/author/book1.epub',
                ),
                _buildSchemaOption(
                  context,
                  DownloadSchema.authorBook,
                  localizations.schemaAuthorBook,
                  '/author/book1/book1.epub',
                ),
                _buildSchemaOption(
                  context,
                  DownloadSchema.authorSeriesBook,
                  localizations.schemaAuthorSeriesBook,
                  '/author/series/book1/book1.epub',
                ),
              ],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text(localizations.cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// Build a schema option for the download schema selection dialog
  ///
  /// Parameters:
  ///
  /// - `context`: The current build context
  /// - `schema`: The schema to select
  /// - `title`: The title of the schema
  /// - `example`: An example of the schema
  Widget _buildSchemaOption(
    BuildContext context,
    DownloadSchema schema,
    String title,
    String example,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        child: Material(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8.0),
          child: InkWell(
            onTap: () {
              Navigator.of(context).pop(schema);
            },
            borderRadius: BorderRadius.circular(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    example,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the color theme selector
  ///
  /// Parameters:
  ///
  /// - `context`: The current build context
  /// - `viewModel`: The settings view model
  /// - `localizations`: The current localizations
  Widget _buildColorThemeSelector(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.palette,
                  size: 28,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    localizations.themeColor,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                DropdownButton<ThemeSource>(
                  value: viewModel.themeSource,
                  underline: Container(),
                  onChanged: (ThemeSource? newValue) {
                    if (newValue != null) {
                      viewModel.setThemeSource(newValue);
                    }
                  },
                  items: [
                    DropdownMenuItem(
                      value: ThemeSource.system,
                      child: Text(localizations.system),
                    ),
                    DropdownMenuItem(
                      value: ThemeSource.custom,
                      child: Text(localizations.custom),
                    ),
                  ],
                ),
              ],
            ),

            if (viewModel.themeSource == ThemeSource.custom) ...[
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children:
                      SettingsViewModel.predefinedColors.entries.map((entry) {
                        final isSelected =
                            viewModel.selectedColorKey == entry.key;

                        return Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: Column(
                            children: [
                              InkWell(
                                onTap:
                                    () => viewModel.setSelectedColor(entry.key),
                                borderRadius: BorderRadius.circular(30),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: entry.value,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          isSelected
                                              ? Theme.of(
                                                context,
                                              ).colorScheme.primary
                                              : Colors.transparent,
                                      width: 3,
                                    ),
                                    boxShadow:
                                        isSelected
                                            ? [
                                              BoxShadow(
                                                // ignore: deprecated_member_use
                                                color: entry.value.withOpacity(
                                                  0.5,
                                                ),
                                                blurRadius: 6,
                                                spreadRadius: 1,
                                              ),
                                            ]
                                            : null,
                                  ),
                                  child:
                                      isSelected
                                          ? const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                          )
                                          : null,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(viewModel.predefinedColorNames[entry.key]!),
                            ],
                          ),
                        );
                      }).toList(),
                ),
              ),
            ],

            if (viewModel.themeSource == ThemeSource.system) ...[
              const SizedBox(height: 12),
              Text(
                localizations.systemThemeDescription,

                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
                ),
              ),
            ],
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

  /// Builds the login settings card
  ///
  /// Parameters:
  ///
  /// - `context`: The current build context
  /// - `localizations`: The current localizations
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
          Navigator.of(
            context,
          ).push(AppTransitions.createSlideRoute(LoginSettings()));
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

  /// Builds the section title
  ///
  /// Parameters:
  ///
  /// - `context`: The current build context
  /// - `title`: The title of the section
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

  /// Builds the downloader toggle
  ///
  /// Parameters:
  ///
  /// - `context`: The current build context
  /// - `viewModel`: The settings view model
  /// - `localizations`: The current localizations
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

  /// Builds a text field
  ///
  /// Parameters:
  ///
  /// - `context`: The current build context
  /// - `controller`: The text controller
  /// - `labelText`: The label text
  /// - `prefixIcon`: The prefix icon
  /// - `hintText`: The hint text
  /// - `obscureText`: Whether the text should be obscured
  /// - `onChanged`: The onChanged callback
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

  /// Builds a theme option
  ///
  /// Parameters:
  ///
  /// - `context`: The current build context
  /// - `mode`: The theme mode
  /// - `icon`: The icon
  /// - `label`: The label
  /// - `viewModel`: The settings view model
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
        onTap: () => viewModel.setTheme(mode),
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

  /// Builds the version card
  ///
  /// Parameters:
  ///
  /// - `context`: The current build context
  /// - `viewModel`: The settings view model
  /// - `localizations`: The current localizations
  Widget _buildVersionCard(
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
