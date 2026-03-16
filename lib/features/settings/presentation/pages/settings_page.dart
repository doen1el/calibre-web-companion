import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:docman/docman.dart';

import 'package:calibre_web_companion/features/settings/bloc/settings_bloc.dart';
import 'package:calibre_web_companion/features/settings/bloc/settings_event.dart';
import 'package:calibre_web_companion/features/settings/bloc/settings_state.dart';

import 'package:calibre_web_companion/features/settings/data/models/book_details_action.dart';
import 'package:calibre_web_companion/features/settings/data/models/book_details_section.dart';
import 'package:calibre_web_companion/features/settings/data/models/discover_layout_config.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/core/services/snackbar.dart';
import 'package:calibre_web_companion/core/services/app_transition.dart';
import 'package:calibre_web_companion/features/login_settings/presentation/pages/login_settings_page.dart';
import 'package:calibre_web_companion/features/settings/presentation/widgets/download_options_widget.dart';
import 'package:calibre_web_companion/features/settings/presentation/widgets/feedback_widget.dart';
import 'package:calibre_web_companion/features/settings/presentation/widgets/theme_selector_widget.dart';
import 'package:calibre_web_companion/features/settings/presentation/widgets/sync_settings_widget.dart';
import 'package:calibre_web_companion/features/settings/presentation/pages/app_logs_page.dart';
import 'package:calibre_web_companion/features/download_service/bloc/download_service_bloc.dart';
import 'package:calibre_web_companion/features/download_service/bloc/download_service_event.dart';

enum SettingsSubPage { discover, bookDetails }

class SettingsPage extends StatefulWidget {
  final SettingsSubPage? initialSubPage;

  const SettingsPage({super.key, this.initialSubPage});

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

  bool _showDownloaderAuth = false;
  bool _didOpenInitialSubPage = false;

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

    _showDownloaderAuth =
        settingsState.downloaderUsername.isNotEmpty ||
        settingsState.downloaderPassword.isNotEmpty;
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

    return _wrapWithSettingsListeners(
      localizations: localizations,
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          if (!_didOpenInitialSubPage &&
              widget.initialSubPage != null &&
              state.status != SettingsStatus.loading) {
            _didOpenInitialSubPage = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              switch (widget.initialSubPage!) {
                case SettingsSubPage.discover:
                  _openDiscoverSettingsSubPage(context);
                case SettingsSubPage.bookDetails:
                  _openBookDetailsSettingsSubPage(context);
              }
            });
          }

          return Scaffold(
            appBar: AppBar(title: Text(localizations.settings)),
            body:
                state.status == SettingsStatus.loading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle(context, localizations.categories),
                          _buildSettingsCategoryNavCard(
                            context,
                            title: localizations.appearance,
                            subtitle: localizations.themeMode,
                            icon: Icons.palette_rounded,
                            onTap:
                                () => _openAppearanceSettingsSubPage(context),
                          ),
                          _buildLoginSettingsCard(context, localizations),
                          _buildSettingsCategoryNavCard(
                            context,
                            title: localizations.downloadOptions,
                            subtitle: localizations.downloadService,
                            icon: Icons.download_rounded,
                            onTap: () => _openDownloadSettingsSubPage(context),
                          ),
                          _buildSettingsCategoryNavCard(
                            context,
                            title: localizations.readerSettings,
                            subtitle: localizations.scrollDirection,
                            icon: Icons.chrome_reader_mode_rounded,
                            onTap: () => _openReaderSettingsSubPage(context),
                          ),
                          _buildSettingsCategoryNavCard(
                            context,
                            title: localizations.discover,
                            subtitle: localizations.categories,
                            icon: Icons.explore_rounded,
                            onTap: () => _openDiscoverSettingsSubPage(context),
                          ),
                          _buildSettingsCategoryNavCard(
                            context,
                            title: localizations.bookDetails,
                            subtitle: localizations.bookActions,
                            icon: Icons.menu_book_rounded,
                            onTap:
                                () => _openBookDetailsSettingsSubPage(context),
                          ),

                          const SizedBox(height: 24),
                          _buildSectionTitle(context, localizations.feedback),
                          const FeedbackWidget(),

                          const SizedBox(height: 24),
                          _buildSectionTitle(context, localizations.about),
                          _buyMeACoffeeButton(context, "Buy Me a Coffee"),
                          _buildAppLogsButton(context, localizations),
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

  Widget _wrapWithSettingsListeners({
    required AppLocalizations localizations,
    required Widget child,
  }) {
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
              Future.delayed(const Duration(milliseconds: 500), () {
                if (context.mounted) {
                  context.read<DownloadServiceBloc>().add(LoadDownloadConfig());
                }
              });
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
      child: child,
    );
  }

  void _openSettingsSubPage({
    required BuildContext context,
    required String title,
    required List<Widget> Function(
      BuildContext context,
      SettingsState state,
      AppLocalizations localizations,
    )
    bodyBuilder,
  }) {
    Navigator.of(context).push(
      AppTransitions.createSlideRoute(
        Builder(
          builder: (context) {
            final localizations = AppLocalizations.of(context)!;
            return _wrapWithSettingsListeners(
              localizations: localizations,
              child: BlocBuilder<SettingsBloc, SettingsState>(
                builder: (context, state) {
                  return Scaffold(
                    appBar: AppBar(title: Text(title)),
                    body:
                        state.status == SettingsStatus.loading
                            ? const Center(child: CircularProgressIndicator())
                            : SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ...bodyBuilder(context, state, localizations),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void _openAppearanceSettingsSubPage(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    _openSettingsSubPage(
      context: context,
      title: localizations.appearance,
      bodyBuilder:
          (context, state, localizations) => [
            _buildSectionTitle(context, localizations.appearance),
            const ThemeSelectorWidget(),
            _buildEInkModeToggle(context, state, localizations),
            const SizedBox(height: 24),
            _buildSectionTitle(context, localizations.language),
            _buildLanguageSelector(context, state, localizations),
          ],
    );
  }

  void _openDownloadSettingsSubPage(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    _openSettingsSubPage(
      context: context,
      title: localizations.downloadOptions,
      bodyBuilder:
          (context, state, localizations) => [
            _buildSectionTitle(context, localizations.downloadOptions),
            const DownloadOptionsWidget(),
            SyncSettingsWidget(),
            const SizedBox(height: 24),
            _buildSectionTitle(context, localizations.customSend2EReader),
            _buildSend2EreaderToggle(context, state, localizations),
            const SizedBox(height: 24),
            _buildSectionTitle(context, 'Shelfmark'),
            _buildDownloaderToggle(context, state, localizations),
          ],
    );
  }

  void _openReaderSettingsSubPage(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    _openSettingsSubPage(
      context: context,
      title: localizations.readerSettings,
      bodyBuilder:
          (context, state, localizations) => [
            _buildSectionTitle(context, localizations.readerSettings),
            _buildReaderSettings(context, state, localizations),
            _buildWebDavSettings(context, state, localizations),
          ],
    );
  }

  void _openDiscoverSettingsSubPage(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    _openSettingsSubPage(
      context: context,
      title: localizations.discover,
      bodyBuilder:
          (context, state, localizations) => [
            _buildSectionTitle(context, localizations.discover),
            _buildDiscoverSettings(context, state, localizations),
          ],
    );
  }

  void _openBookDetailsSettingsSubPage(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    _openSettingsSubPage(
      context: context,
      title: localizations.bookDetails,
      bodyBuilder:
          (context, state, localizations) => [
            _buildSectionTitle(context, localizations.bookDetails),
            _buildBookDetailsSettings(context, state, localizations),
          ],
    );
  }

  Widget _buildSettingsCategoryNavCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8.0),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                icon,
                size: 28,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
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

  Widget _buildEInkModeToggle(
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
              Icons.e_mobiledata,
              size: 28,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.eInkMode,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    localizations.eInkModeDescription,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: state.isEInkMode,
              activeThumbColor: Theme.of(context).colorScheme.primary,
              onChanged: (value) {
                context.read<SettingsBloc>().add(SetEInkMode(value));
              },
            ),
          ],
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
                  activeThumbColor: Theme.of(context).colorScheme.primary,
                  onChanged: (value) {
                    context.read<SettingsBloc>().add(
                      SetDownloaderEnabled(value),
                    );
                    if (value) {
                      context.read<DownloadServiceBloc>().add(
                        LoadDownloadConfig(),
                      );
                    }
                  },
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
              const SizedBox(height: 8),
              Text(
                localizations.enterUrlOfYourDownloadService,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.lock_person,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      localizations.authentication,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  Switch(
                    value: _showDownloaderAuth,
                    activeThumbColor: Theme.of(context).colorScheme.primary,
                    onChanged: (value) {
                      setState(() {
                        _showDownloaderAuth = value;
                      });
                    },
                  ),
                ],
              ),
              if (_showDownloaderAuth) ...[
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
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    if (state.downloaderTestStatus ==
                        ConnectionTestStatus.loading) {
                      return;
                    }

                    final username =
                        _showDownloaderAuth
                            ? _downloaderUsernameController.text.trim()
                            : '';
                    final password =
                        _showDownloaderAuth
                            ? _downloaderPasswordController.text
                            : '';

                    if (state.downloaderTestStatus ==
                        ConnectionTestStatus.success) {
                      context.read<SettingsBloc>().add(
                        SetDownloaderUrl(_downloaderUrlController.text.trim()),
                      );
                      context.read<SettingsBloc>().add(
                        SetDownloaderCredentials(username, password),
                      );
                      context.showSnackBar(localizations.settingsSaved);
                      FocusScope.of(context).unfocus();
                    } else {
                      context.read<SettingsBloc>().add(
                        TestDownloaderConnection(
                          url: _downloaderUrlController.text.trim(),
                          username: username,
                          password: password,
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
                            ? (_showDownloaderAuth
                                ? localizations.saveCredentials
                                : localizations.save)
                            : localizations.testConnection),
                  ),
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
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.download_for_offline_rounded,
                    size: 24,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.storeReadNowAndSendToEReaderOnDevice,
                        ),
                        SizedBox(height: 4),
                        Text(
                          localizations
                              .storeReadNowAndSendToEReaderOnDeviceDescription,
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: state.storeReadNowAndSendToEReaderOnDevice,
                    onChanged: (value) async {
                      if (!value) {
                        context.read<SettingsBloc>().add(
                          const SetStoreReadNowAndSendToEReaderOnDevice(false),
                        );
                        return;
                      }

                      if (state.defaultDownloadPath.isEmpty) {
                        final selectedDirectory = await DocMan.pick.directory();
                        if (selectedDirectory == null) {
                          if (context.mounted) {
                            context.showSnackBar(
                              localizations.noFolderWasSelected,
                              isError: true,
                            );
                          }
                          return;
                        }

                        if (context.mounted) {
                          context.read<SettingsBloc>().add(
                            SetDownloadFolder(selectedDirectory.uri),
                          );
                        }
                      }

                      if (context.mounted) {
                        context.read<SettingsBloc>().add(
                          const SetStoreReadNowAndSendToEReaderOnDevice(true),
                        );
                      }
                    },
                    activeThumbColor: Theme.of(context).colorScheme.primary,
                  ),
                ],
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
      {'code': 'hu', 'name': 'Magyar', 'flag': '🇭🇺'},
      {'code': 'sv', 'name': 'Svenska', 'flag': '🇸🇪'},
      {'code': 'tr', 'name': 'Türkçe', 'flag': '🇹🇷'},
      {'code': 'ca', 'name': 'Català', 'flag': '🇦🇩'},
      {'code': 'ru', 'name': 'Русский', 'flag': '🇷🇺'},
      {'code': 'ar', 'name': 'العربية', 'flag': '🇸🇦'},
      {'code': 'zh', 'name': '中文', 'flag': '🇨🇳'},
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
                  Icons.send,
                  size: 28,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.showSendToEReaderButton,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        localizations.showSendToEReaderButtonDescription,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: state.showSendToEReaderButton,
                  onChanged: (value) {
                    context.read<SettingsBloc>().add(
                      SetShowSendToEReaderButton(value),
                    );
                  },
                  activeThumbColor: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 20),
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
                  onChanged:
                      state.showSendToEReaderButton
                          ? (value) {
                            context.read<SettingsBloc>().add(
                              SetShowReadNowButton(value),
                            );
                          }
                          : null,
                  activeThumbColor: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 8),
            _buildBookActionsCustomization(context, state, localizations),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 8),
            _buildBookSectionsCustomization(context, state, localizations),
          ],
        ),
      ),
    );
  }

  Widget _buildBookActionsCustomization(
    BuildContext context,
    SettingsState state,
    AppLocalizations localizations,
  ) {
    final orderedActions =
        state.bookActionsOrder
            .map(BookDetailsActionX.fromKey)
            .whereType<BookDetailsAction>()
            .toList();
    final enabledActions = state.enabledBookActions.toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.tune_rounded,
              size: 24,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(width: 12),
            Text(
              localizations.bookActions,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            IconButton(
              tooltip: localizations.reset,
              onPressed: () {
                context.read<SettingsBloc>().add(
                  const ResetBookActionsCustomization(),
                );
              },
              icon: const Icon(Icons.restart_alt_rounded),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          proxyDecorator:
              (child, index, animation) =>
                  Material(type: MaterialType.transparency, child: child),
          itemCount: orderedActions.length,
          onReorder: (oldIndex, newIndex) {
            final updated = List<String>.from(state.bookActionsOrder);
            if (newIndex > oldIndex) {
              newIndex -= 1;
            }
            final item = updated.removeAt(oldIndex);
            updated.insert(newIndex, item);
            context.read<SettingsBloc>().add(SetBookActionsOrder(updated));
          },
          itemBuilder: (context, index) {
            final action = orderedActions[index];
            final actionKey = action.key;

            return Card(
              key: ValueKey(actionKey),
              margin: const EdgeInsets.symmetric(vertical: 4),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                leading: Icon(
                  _bookActionIcon(action),
                  color: Theme.of(context).colorScheme.secondary,
                ),
                title: Text(_bookActionTitle(action, localizations)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: enabledActions.contains(actionKey),
                      onChanged: (value) {
                        context.read<SettingsBloc>().add(
                          SetBookActionEnabled(
                            actionKey: actionKey,
                            enabled: value,
                          ),
                        );
                      },
                    ),
                    ReorderableDragStartListener(
                      index: index,
                      child: Icon(
                        Icons.drag_handle_rounded,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  String _bookActionTitle(
    BookDetailsAction action,
    AppLocalizations localizations,
  ) {
    switch (action) {
      case BookDetailsAction.toggleReadStatus:
        return localizations.markAsReadUnread;
      case BookDetailsAction.toggleArchiveStatus:
        return localizations.archiveUnarchive;
      case BookDetailsAction.editMetadata:
        return localizations.editBookMetadata;
      case BookDetailsAction.addToShelf:
        return localizations.addToShelf;
      case BookDetailsAction.downloadToDevice:
        return localizations.downloadToDevice;
      case BookDetailsAction.openInInternalReader:
        return localizations.openInInternalReader;
      case BookDetailsAction.openInReader:
        return localizations.openInReader;
      case BookDetailsAction.openInBrowser:
        return localizations.openBookInBrowser;
      case BookDetailsAction.deleteBook:
        return localizations.deleteBook;
    }
  }

  IconData _bookActionIcon(BookDetailsAction action) {
    switch (action) {
      case BookDetailsAction.toggleReadStatus:
        return Icons.visibility_off;
      case BookDetailsAction.toggleArchiveStatus:
        return Icons.unarchive;
      case BookDetailsAction.editMetadata:
        return Icons.edit;
      case BookDetailsAction.addToShelf:
        return Icons.playlist_add_rounded;
      case BookDetailsAction.downloadToDevice:
        return Icons.download_rounded;
      case BookDetailsAction.openInInternalReader:
        return Icons.menu_book_rounded;
      case BookDetailsAction.openInReader:
        return Icons.open_in_new_rounded;
      case BookDetailsAction.openInBrowser:
        return Icons.open_in_browser_rounded;
      case BookDetailsAction.deleteBook:
        return Icons.delete_rounded;
    }
  }

  Widget _buildBookSectionsCustomization(
    BuildContext context,
    SettingsState state,
    AppLocalizations localizations,
  ) {
    final orderedSections =
        BookDetailsSectionConfig.normalizeOrder(state.bookDetailsSectionsOrder)
            .map(BookDetailsSectionX.fromKey)
            .whereType<BookDetailsSection>()
            .toList();
    final enabledSections =
        BookDetailsSectionConfig.normalizeEnabled(
          state.enabledBookDetailsSections,
        ).toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.view_list_rounded,
              size: 24,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(width: 12),
            Text(
              localizations.bookDetails,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            IconButton(
              tooltip: localizations.reset,
              onPressed: () {
                context.read<SettingsBloc>().add(
                  const ResetBookDetailsSectionsCustomization(),
                );
              },
              icon: const Icon(Icons.restart_alt_rounded),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          proxyDecorator:
              (child, index, animation) =>
                  Material(type: MaterialType.transparency, child: child),
          itemCount: orderedSections.length,
          onReorder: (oldIndex, newIndex) {
            final updated = List<String>.from(
              BookDetailsSectionConfig.normalizeOrder(
                state.bookDetailsSectionsOrder,
              ),
            );
            if (newIndex > oldIndex) {
              newIndex -= 1;
            }
            final item = updated.removeAt(oldIndex);
            updated.insert(newIndex, item);
            context.read<SettingsBloc>().add(
              SetBookDetailsSectionsOrder(updated),
            );
          },
          itemBuilder: (context, index) {
            final section = orderedSections[index];
            final sectionKey = section.key;

            return Card(
              key: ValueKey(sectionKey),
              margin: const EdgeInsets.symmetric(vertical: 4),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                leading: Icon(
                  _bookSectionIcon(section),
                  color: Theme.of(context).colorScheme.secondary,
                ),
                title: Text(_bookSectionTitle(section, localizations)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: enabledSections.contains(sectionKey),
                      onChanged: (value) {
                        context.read<SettingsBloc>().add(
                          SetBookDetailsSectionEnabled(
                            sectionKey: sectionKey,
                            enabled: value,
                          ),
                        );
                      },
                    ),
                    ReorderableDragStartListener(
                      index: index,
                      child: Icon(
                        Icons.drag_handle_rounded,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  String _bookSectionTitle(
    BookDetailsSection section,
    AppLocalizations localizations,
  ) {
    switch (section) {
      case BookDetailsSection.bookActions:
        return localizations.bookActions;
      case BookDetailsSection.rating:
        return localizations.rating;
      case BookDetailsSection.series:
        return localizations.series;
      case BookDetailsSection.publicationInfo:
        return localizations.publicationInfo;
      case BookDetailsSection.fileInfo:
        return localizations.fileInfo;
      case BookDetailsSection.tags:
        return localizations.tags;
      case BookDetailsSection.description:
        return localizations.description;
    }
  }

  IconData _bookSectionIcon(BookDetailsSection section) {
    switch (section) {
      case BookDetailsSection.bookActions:
        return Icons.menu_book_rounded;
      case BookDetailsSection.rating:
        return Icons.star_rate_rounded;
      case BookDetailsSection.series:
        return Icons.bookmark_rounded;
      case BookDetailsSection.publicationInfo:
        return Icons.info_outline_rounded;
      case BookDetailsSection.fileInfo:
        return Icons.description_rounded;
      case BookDetailsSection.tags:
        return Icons.local_offer_rounded;
      case BookDetailsSection.description:
        return Icons.article_rounded;
    }
  }

  Widget _buildDiscoverSettings(
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
            _buildDiscoverMainSectionsCustomization(
              context,
              state,
              localizations,
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 8),
            _buildDiscoverItemsCustomization(context, state, localizations),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 8),
            _buildCategoryItemsCustomization(context, state, localizations),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoverMainSectionsCustomization(
    BuildContext context,
    SettingsState state,
    AppLocalizations localizations,
  ) {
    final orderedSections =
        DiscoverLayoutConfig.normalizeMainSectionsOrder(
              state.discoverMainSectionsOrder,
            )
            .map(DiscoverMainSectionX.fromKey)
            .whereType<DiscoverMainSection>()
            .toList();
    final enabledSections =
        DiscoverLayoutConfig.normalizeEnabledMainSections(
          state.enabledDiscoverMainSections,
        ).toSet();

    return _buildSettingsReorderList(
      context: context,
      title: localizations.discover,
      icon: Icons.view_stream_rounded,
      resetTooltip: localizations.reset,
      onReset:
          () => context.read<SettingsBloc>().add(
            const ResetDiscoverCustomization(),
          ),
      itemCount: orderedSections.length,
      onReorder: (oldIndex, newIndex) {
        final updated = List<String>.from(
          DiscoverLayoutConfig.normalizeMainSectionsOrder(
            state.discoverMainSectionsOrder,
          ),
        );
        if (newIndex > oldIndex) newIndex -= 1;
        final item = updated.removeAt(oldIndex);
        updated.insert(newIndex, item);
        context.read<SettingsBloc>().add(SetDiscoverMainSectionsOrder(updated));
      },
      tileBuilder: (index) {
        final section = orderedSections[index];
        final sectionKey = section.key;
        return _settingsReorderTile(
          context: context,
          keyValue: sectionKey,
          leading: Icon(
            _discoverMainSectionIcon(section),
            color: Theme.of(context).colorScheme.secondary,
          ),
          title: _discoverMainSectionTitle(section, localizations),
          value: enabledSections.contains(sectionKey),
          onChanged:
              (value) => context.read<SettingsBloc>().add(
                SetDiscoverMainSectionEnabled(
                  sectionKey: sectionKey,
                  enabled: value,
                ),
              ),
          index: index,
        );
      },
    );
  }

  Widget _buildDiscoverItemsCustomization(
    BuildContext context,
    SettingsState state,
    AppLocalizations localizations,
  ) {
    final orderedItems =
        DiscoverLayoutConfig.normalizeDiscoverItemsOrder(
          state.discoverItemsOrder,
        ).map(DiscoverItemX.fromKey).whereType<DiscoverItem>().toList();
    final enabledItems =
        DiscoverLayoutConfig.normalizeEnabledDiscoverItems(
          state.enabledDiscoverItems,
        ).toSet();

    return _buildSettingsReorderList(
      context: context,
      title: localizations.discover,
      icon: Icons.search_rounded,
      itemCount: orderedItems.length,
      onReorder: (oldIndex, newIndex) {
        final updated = List<String>.from(
          DiscoverLayoutConfig.normalizeDiscoverItemsOrder(
            state.discoverItemsOrder,
          ),
        );
        if (newIndex > oldIndex) newIndex -= 1;
        final item = updated.removeAt(oldIndex);
        updated.insert(newIndex, item);
        context.read<SettingsBloc>().add(SetDiscoverItemsOrder(updated));
      },
      tileBuilder: (index) {
        final item = orderedItems[index];
        final itemKey = item.key;
        return _settingsReorderTile(
          context: context,
          keyValue: itemKey,
          leading: Icon(
            _discoverItemIcon(item),
            color: Theme.of(context).colorScheme.secondary,
          ),
          title: _discoverItemTitle(item, localizations),
          value: enabledItems.contains(itemKey),
          onChanged:
              (value) => context.read<SettingsBloc>().add(
                SetDiscoverItemEnabled(itemKey: itemKey, enabled: value),
              ),
          index: index,
        );
      },
    );
  }

  Widget _buildCategoryItemsCustomization(
    BuildContext context,
    SettingsState state,
    AppLocalizations localizations,
  ) {
    final orderedItems =
        DiscoverLayoutConfig.normalizeCategoryItemsOrder(
          state.categoryItemsOrder,
        ).map(CategoryItemX.fromKey).whereType<CategoryItem>().toList();
    final enabledItems =
        DiscoverLayoutConfig.normalizeEnabledCategoryItems(
          state.enabledCategoryItems,
        ).toSet();

    return _buildSettingsReorderList(
      context: context,
      title: localizations.categories,
      icon: Icons.category_rounded,
      itemCount: orderedItems.length,
      onReorder: (oldIndex, newIndex) {
        final updated = List<String>.from(
          DiscoverLayoutConfig.normalizeCategoryItemsOrder(
            state.categoryItemsOrder,
          ),
        );
        if (newIndex > oldIndex) newIndex -= 1;
        final item = updated.removeAt(oldIndex);
        updated.insert(newIndex, item);
        context.read<SettingsBloc>().add(SetCategoryItemsOrder(updated));
      },
      tileBuilder: (index) {
        final item = orderedItems[index];
        final itemKey = item.key;
        return _settingsReorderTile(
          context: context,
          keyValue: itemKey,
          leading: Icon(
            _categoryItemIcon(item),
            color: Theme.of(context).colorScheme.secondary,
          ),
          title: _categoryItemTitle(item, localizations),
          value: enabledItems.contains(itemKey),
          onChanged:
              (value) => context.read<SettingsBloc>().add(
                SetCategoryItemEnabled(itemKey: itemKey, enabled: value),
              ),
          index: index,
        );
      },
    );
  }

  Widget _buildSettingsReorderList({
    required BuildContext context,
    required String title,
    required IconData icon,
    String? resetTooltip,
    VoidCallback? onReset,
    required int itemCount,
    required void Function(int oldIndex, int newIndex) onReorder,
    required Widget Function(int index) tileBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(width: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            if (onReset != null) ...[
              const Spacer(),
              IconButton(
                tooltip: resetTooltip,
                onPressed: onReset,
                icon: const Icon(Icons.restart_alt_rounded),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          proxyDecorator:
              (child, index, animation) =>
                  Material(type: MaterialType.transparency, child: child),
          itemCount: itemCount,
          onReorder: onReorder,
          itemBuilder: (context, index) => tileBuilder(index),
        ),
      ],
    );
  }

  Widget _settingsReorderTile({
    required BuildContext context,
    required String keyValue,
    required Widget leading,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required int index,
  }) {
    return Card(
      key: ValueKey(keyValue),
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: leading,
        title: Text(title),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(value: value, onChanged: onChanged),
            ReorderableDragStartListener(
              index: index,
              child: Icon(
                Icons.drag_handle_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _discoverMainSectionTitle(
    DiscoverMainSection section,
    AppLocalizations localizations,
  ) {
    switch (section) {
      case DiscoverMainSection.discover:
        return localizations.discover;
      case DiscoverMainSection.categories:
        return localizations.categories;
    }
  }

  IconData _discoverMainSectionIcon(DiscoverMainSection section) {
    switch (section) {
      case DiscoverMainSection.discover:
        return Icons.search_rounded;
      case DiscoverMainSection.categories:
        return Icons.category_rounded;
    }
  }

  String _discoverItemTitle(DiscoverItem item, AppLocalizations localizations) {
    switch (item) {
      case DiscoverItem.discover:
        return localizations.discover;
      case DiscoverItem.hotBooks:
        return localizations.showHotBooks;
      case DiscoverItem.newBooks:
        return localizations.showNewBooks;
      case DiscoverItem.ratedBooks:
        return localizations.showRatedBooks;
    }
  }

  IconData _discoverItemIcon(DiscoverItem item) {
    switch (item) {
      case DiscoverItem.discover:
        return Icons.search;
      case DiscoverItem.hotBooks:
        return Icons.local_fire_department_rounded;
      case DiscoverItem.newBooks:
        return Icons.new_releases_rounded;
      case DiscoverItem.ratedBooks:
        return Icons.star_border_rounded;
    }
  }

  String _categoryItemTitle(CategoryItem item, AppLocalizations localizations) {
    switch (item) {
      case CategoryItem.authors:
        return localizations.showAuthors;
      case CategoryItem.categories:
        return localizations.showCategories;
      case CategoryItem.series:
        return localizations.showSeries;
      case CategoryItem.formats:
        return localizations.showFormats;
      case CategoryItem.languages:
        return localizations.showLanguages;
      case CategoryItem.publishers:
        return localizations.showPublishers;
      case CategoryItem.ratings:
        return localizations.showRatings;
    }
  }

  IconData _categoryItemIcon(CategoryItem item) {
    switch (item) {
      case CategoryItem.authors:
        return Icons.people_rounded;
      case CategoryItem.categories:
        return Icons.category_rounded;
      case CategoryItem.series:
        return Icons.library_books_rounded;
      case CategoryItem.formats:
        return Icons.file_open_rounded;
      case CategoryItem.languages:
        return Icons.language_rounded;
      case CategoryItem.publishers:
        return Icons.business_rounded;
      case CategoryItem.ratings:
        return Icons.star_rounded;
    }
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

  Widget _buildAppLogsButton(
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
          ).push(AppTransitions.createSlideRoute(const AppLogsPage()));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.bug_report_rounded,
                size: 28,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.appLogs,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      localizations.openAndCopyLogs,
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
