import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:calibre_web_companion/features/settings/bloc/settings_bloc.dart';
import 'package:calibre_web_companion/features/settings/bloc/settings_event.dart';
import 'package:calibre_web_companion/features/settings/bloc/settings_state.dart';

import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/core/services/snackbar.dart';
import 'package:calibre_web_companion/core/services/app_transition.dart';
import 'package:calibre_web_companion/features/login_settings/presentation/pages/login_settings_page.dart';
import 'package:calibre_web_companion/features/settings/presentation/widgets/download_options_widget.dart';
import 'package:calibre_web_companion/features/settings/presentation/widgets/feedback_widget.dart';
import 'package:calibre_web_companion/features/settings/presentation/widgets/theme_selector_widget.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _send2ereaderUrlController =
      TextEditingController();
  final TextEditingController _downloaderUrlController =
      TextEditingController();
  final TextEditingController _downloaderUsernameController =
      TextEditingController();
  final TextEditingController _downloaderPasswordController =
      TextEditingController();
  final TextEditingController _webDavUrlController = TextEditingController();
  final TextEditingController _webDavUsernameController =
      TextEditingController();
  final TextEditingController _webDavPasswordController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    final settingsState = context.read<SettingsBloc>().state;
    _send2ereaderUrlController.text = settingsState.send2ereaderUrl;
    _downloaderUrlController.text = settingsState.downloaderUrl;
    _downloaderUsernameController.text = settingsState.downloaderUsername;
    _downloaderPasswordController.text = settingsState.downloaderPassword;
    _webDavUrlController.text = settingsState.webDavUrl;
    _webDavUsernameController.text = settingsState.webDavUsername;
    _webDavPasswordController.text = settingsState.webDavPassword;
  }

  @override
  void dispose() {
    _send2ereaderUrlController.dispose();
    _downloaderUrlController.dispose();
    _downloaderUsernameController.dispose();
    _downloaderPasswordController.dispose();
    _webDavUrlController.dispose();
    _webDavUsernameController.dispose();
    _webDavPasswordController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settingsState = context.read<SettingsBloc>().state;

    if (_send2ereaderUrlController.text != settingsState.send2ereaderUrl) {
      _send2ereaderUrlController.text = settingsState.send2ereaderUrl;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return MultiBlocListener(
      listeners: [
        BlocListener<SettingsBloc, SettingsState>(
          listenWhen: (previous, current) => previous.status != current.status,
          listener: (context, state) {
            if (state.status == SettingsStatus.error) {
              context.showSnackBar(
                state.errorMessage ?? localizations.unknownError,
                isError: true,
              );
            }
          },
        ),
        BlocListener<SettingsBloc, SettingsState>(
          listenWhen:
              (previous, current) =>
                  previous.downloaderTestStatus != current.downloaderTestStatus,
          listener: (context, state) {
            if (state.downloaderTestStatus == ConnectionTestStatus.success) {
              context.showSnackBar(
                localizations.connectionTestSuccessful,
                isError: false,
              );
            } else if (state.downloaderTestStatus ==
                ConnectionTestStatus.error) {
              context.showSnackBar(
                state.testErrorMessage ?? localizations.connectionError,
                isError: true,
              );
            }
          },
        ),
        BlocListener<SettingsBloc, SettingsState>(
          listenWhen:
              (previous, current) =>
                  previous.webDavTestStatus != current.webDavTestStatus,
          listener: (context, state) {
            if (state.webDavTestStatus == ConnectionTestStatus.success) {
              context.showSnackBar(
                localizations.connectionTestSuccessful,
                isError: false,
              );
            } else if (state.webDavTestStatus == ConnectionTestStatus.error) {
              context.showSnackBar(
                state.testErrorMessage ?? localizations.connectionError,
                isError: true,
              );
            }
          },
        ),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
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
                          _buildSectionTitle(
                            context,
                            localizations.downloadOptions,
                          ),
                          const DownloadOptionsWidget(),

                          const SizedBox(height: 24),
                          _buildSectionTitle(
                            context,
                            localizations.customSend2EReader,
                          ),
                          _buildSend2EreaderToggle(
                            context,
                            state,
                            localizations,
                          ),

                          const SizedBox(height: 24),
                          _buildSectionTitle(
                            context,
                            "Calibre Web Automated Downloader",
                          ),
                          _buildDownloaderToggle(context, state, localizations),

                          const SizedBox(height: 24),
                          _buildSectionTitle(
                            context,
                            localizations.readerSettings,
                          ),
                          _buildReaderSettings(context, state, localizations),
                          _buildWebDavSettings(context, state, localizations),

                          const SizedBox(height: 24),
                          _buildSectionTitle(context, localizations.language),
                          _buildLanguageSelector(context, state, localizations),

                          const SizedBox(height: 24),
                          _buildSectionTitle(
                            context,
                            localizations.bookDetails,
                          ),
                          _buildBookDetailsSettings(
                            context,
                            state,
                            localizations,
                          ),

                          const SizedBox(height: 24),
                          _buildSectionTitle(context, localizations.feedback),
                          const FeedbackWidget(),

                          const SizedBox(height: 24),
                          _buildSectionTitle(context, localizations.about),
                          _buyMeACoffeeButton(context, "Buy Me a Coffee"),
                          _buildLicensesButton(context, state, localizations),
                          _buildVersionCard(context, state, localizations),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
          );
        },
      ),
    );
  }

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
                  activeThumbColor: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),

            if (state.isDownloaderEnabled) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _downloaderUrlController,
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
                    (_) => context.read<SettingsBloc>().add(
                      ResetConnectionTestStatus(),
                    ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _downloaderUsernameController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  labelText: localizations.username,
                  prefixIcon: const Icon(Icons.person),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 14.0,
                  ),
                ),
                onChanged:
                    (_) => context.read<SettingsBloc>().add(
                      ResetConnectionTestStatus(),
                    ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _downloaderPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  labelText: localizations.password,
                  prefixIcon: const Icon(Icons.lock),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 14.0,
                  ),
                ),
                onChanged:
                    (_) => context.read<SettingsBloc>().add(
                      ResetConnectionTestStatus(),
                    ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    if (state.downloaderTestStatus ==
                        ConnectionTestStatus.loading) {
                      return;
                    }

                    if (state.downloaderTestStatus ==
                        ConnectionTestStatus.success) {
                      context.read<SettingsBloc>().add(
                        SetDownloaderUrl(_downloaderUrlController.text.trim()),
                      );
                      context.read<SettingsBloc>().add(
                        SetDownloaderCredentials(
                          _downloaderUsernameController.text.trim(),
                          _downloaderPasswordController.text,
                        ),
                      );
                      context.showSnackBar(localizations.settingsSaved);
                      FocusScope.of(context).unfocus();
                    } else {
                      context.read<SettingsBloc>().add(
                        TestDownloaderConnection(
                          url: _downloaderUrlController.text.trim(),
                          username: _downloaderUsernameController.text.trim(),
                          password: _downloaderPasswordController.text,
                        ),
                      );
                    }
                  },
                  icon:
                      state.downloaderTestStatus == ConnectionTestStatus.loading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(),
                          )
                          : Icon(
                            state.downloaderTestStatus ==
                                    ConnectionTestStatus.success
                                ? Icons.check_circle
                                : Icons.wifi_find,
                          ),
                  label: Text(
                    state.downloaderTestStatus == ConnectionTestStatus.loading
                        ? localizations.testing
                        : (state.downloaderTestStatus ==
                                ConnectionTestStatus.success
                            ? localizations.saveCredentials
                            : localizations.testConnection),
                  ),
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

  Widget _buildSend2EreaderToggle(
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
                  activeThumbColor: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),

            if (state.isSend2ereaderEnabled) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _send2ereaderUrlController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  labelText: localizations.send2ereaderServiceUrl,
                  hintText: "https://send.djazz.se",
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
    final availableLanguages = [
      {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
      {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪'},
      {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
      {'code': 'es', 'name': 'Español', 'flag': '🇪🇸'},
      {'code': 'pt', 'name': 'Português', 'flag': '🇵🇹'},
      {'code': 'et', 'name': 'Eesti', 'flag': '🇪🇪'},
      {'code': 'it', 'name': 'Italiano', 'flag': '🇮🇹'},
    ];

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
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              initialValue: state.languageCode,
              icon: const Icon(Icons.arrow_drop_down),
              elevation: 16,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
              ),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  context.read<SettingsBloc>().add(SetLanguage(newValue));
                }
              },
              items:
                  availableLanguages.map<DropdownMenuItem<String>>((language) {
                    return DropdownMenuItem<String>(
                      value: language['code'],
                      child: Row(
                        children: [
                          Text(
                            language['flag'] ?? '',
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: 12),
                          Text(language['name'] ?? ''),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buyMeACoffeeButton(BuildContext context, String title) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8.0),
        onTap: () {
          context.read<SettingsBloc>().add(BuyMeACoffee());
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.coffee,
                size: 28,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 16),

              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookDetailsSettings(
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
          children: [
            Row(
              children: [
                Icon(
                  Icons.visibility_rounded,
                  size: 28,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.showReadNowButton,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        localizations.showReadNowButtonDescription,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: state.showReadNowButton,
                  onChanged: (value) {
                    context.read<SettingsBloc>().add(
                      SetShowReadNowButton(value),
                    );
                  },
                  activeThumbColor: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLicensesButton(
    BuildContext context,
    SettingsState state,
    AppLocalizations localizations,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8.0),
        onTap: () {
          showLicensePage(
            context: context,
            applicationName: 'Calibre Web Companion',
            applicationVersion:
                "${state.appVersion ?? ''} (${state.buildNumber ?? ''})",
            applicationIcon: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset('assets/icon.png', width: 60, height: 60),
            ),
            useRootNavigator: true,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.description_outlined,
                size: 28,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  localizations.licenses,
                  style: Theme.of(context).textTheme.titleMedium,
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

  Widget _buildWebDavSettings(
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
          children: [
            Row(
              children: [
                Icon(
                  Icons.cloud_sync_rounded,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    localizations.webDavSync,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Switch(
                  value: state.isWebDavSyncEnabled,
                  activeThumbColor: Theme.of(context).colorScheme.primary,
                  onChanged: (value) {
                    context.read<SettingsBloc>().add(
                      SetWebDavSyncEnabled(value),
                    );
                  },
                ),
              ],
            ),

            if (state.isWebDavSyncEnabled) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _webDavUrlController,
                decoration: InputDecoration(
                  labelText: "WebDAV URL (e.g. Nextcloud)",
                  hintText:
                      "https://cloud.example.com/remote.php/dav/files/user/",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  prefixIcon: const Icon(Icons.link),
                ),
                onChanged:
                    (_) => context.read<SettingsBloc>().add(
                      ResetConnectionTestStatus(),
                    ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _webDavUsernameController,
                decoration: InputDecoration(
                  labelText: localizations.username,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
                onChanged:
                    (_) => context.read<SettingsBloc>().add(
                      ResetConnectionTestStatus(),
                    ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _webDavPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: localizations.password,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                ),
                onChanged:
                    (_) => context.read<SettingsBloc>().add(
                      ResetConnectionTestStatus(),
                    ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    if (state.webDavTestStatus ==
                        ConnectionTestStatus.loading) {
                      return;
                    }

                    if (state.webDavTestStatus ==
                        ConnectionTestStatus.success) {
                      context.read<SettingsBloc>().add(
                        SetWebDavUrl(_webDavUrlController.text.trim()),
                      );
                      context.read<SettingsBloc>().add(
                        SetWebDavCredentials(
                          _webDavUsernameController.text.trim(),
                          _webDavPasswordController.text,
                        ),
                      );
                      context.showSnackBar(localizations.settingsSaved);
                      FocusScope.of(context).unfocus();
                    } else {
                      context.read<SettingsBloc>().add(
                        TestWebDavConnection(
                          url: _webDavUrlController.text.trim(),
                          username: _webDavUsernameController.text.trim(),
                          password: _webDavPasswordController.text,
                        ),
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  icon:
                      state.webDavTestStatus == ConnectionTestStatus.loading
                          ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          )
                          : Icon(
                            state.webDavTestStatus ==
                                    ConnectionTestStatus.success
                                ? Icons.check_circle
                                : Icons.wifi_find,
                          ),
                  label: Text(
                    state.webDavTestStatus == ConnectionTestStatus.loading
                        ? localizations.testing
                        : (state.webDavTestStatus ==
                                ConnectionTestStatus.success
                            ? localizations.save
                            : localizations.testConnection),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                localizations.syncsReadingProgress,
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

  Widget _buildReaderSettings(
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
          children: [
            Row(
              children: [
                Icon(
                  Icons.chrome_reader_mode_rounded,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    localizations.scrollDirection,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              initialValue: state.epubScrollDirection,
              icon: const Icon(Icons.arrow_drop_down),
              elevation: 16,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
              ),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  context.read<SettingsBloc>().add(
                    SetEpubScrollDirection(newValue),
                  );
                }
              },
              items: [
                DropdownMenuItem<String>(
                  value: 'vertical',
                  child: Text(localizations.vertical),
                ),
                DropdownMenuItem<String>(
                  value: 'horizontal',
                  child: Text(localizations.horizontal),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
