import 'package:calibre_web_companion/view_models/login_settings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LoginSettings extends StatefulWidget {
  const LoginSettings({super.key});

  @override
  LoginSettingsState createState() => LoginSettingsState();
}

class LoginSettingsState extends State<LoginSettings>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _basePathController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Provider.of<LoginSettingsViewModel>(context, listen: false).loadSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _basePathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LoginSettingsViewModel>();
    final localizations = AppLocalizations.of(context)!;

    if (viewModel.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(localizations.connectionSettings)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Set the initial value of the base path text field
    _basePathController.text =
        viewModel.basePath.startsWith('/')
            ? viewModel.basePath.substring(1)
            : viewModel.basePath;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.connectionSettings),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: localizations.headers, icon: const Icon(Icons.code)),
            Tab(
              text: localizations.authSystems,
              icon: const Icon(Icons.security),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: localizations.save,
            onPressed: () {
              viewModel.saveAllSettings();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(localizations.settingsSaved)),
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Custom HTTP Headers
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(context, localizations.costumHttpPHeader),
                _buildHeadersCard(context, viewModel, localizations),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 16.0,
                  ),
                  child: Center(
                    child: ElevatedButton.icon(
                      onPressed: viewModel.addHeader,
                      icon: const Icon(Icons.add),
                      label: Text(localizations.addHeader),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tab 2: Authentication Systems
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(context, localizations.basePath),
                Card(
                  margin: const EdgeInsets.only(bottom: 24.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.basePathDescription,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _basePathController,
                          decoration: InputDecoration(
                            labelText: localizations.basePath,
                            hintText: 'calibre',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            prefixText: '/',
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface,
                          ),
                          onChanged: (value) {
                            viewModel.setBasePath(value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                _buildSectionTitle(context, localizations.authSystem),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.authSystemDescription,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        ...viewModel.authSystemNames.entries.map((entry) {
                          return RadioListTile<AuthSystem>(
                            title: Text(entry.value),
                            value: entry.key,
                            groupValue: viewModel.selectedAuthSystem,
                            onChanged: (AuthSystem? value) {
                              if (value != null) {
                                viewModel.setAuthSystem(value);
                              }
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                _buildSectionTitle(context, localizations.helpAndInfo),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(localizations.authSystemHelp1),
                        ),
                        const Divider(),
                        ListTile(
                          leading: Icon(
                            Icons.security,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(localizations.authSystemHelp2),
                        ),
                        const Divider(),
                        ListTile(
                          leading: Icon(
                            Icons.code,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(localizations.authSystemHelp3),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build a section title with the same style as SettingsView
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

  /// Build the card for the custom HTTP headers
  Widget _buildHeadersCard(
    BuildContext context,
    LoginSettingsViewModel viewModel,
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
                  Icons.code_rounded,
                  size: 28,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.httpHeader,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        localizations
                            .addACostumHttpHeaderThatWillBeSentWithEveryRequest,
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

            // Header List
            if (viewModel.customHeaders.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Text(
                    localizations.noCostumHttpHeadersYet,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              ...viewModel.customHeaders.asMap().entries.map((entry) {
                final index = entry.key;
                final header = entry.value;
                final key = header.keys.first;
                final value = header.values.first;

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
                          onPressed: () => viewModel.deleteHeader(index),
                          tooltip: localizations.deleteHeader,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minHeight: 36,
                            minWidth: 36,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    _buildTextField(
                      context: context,
                      initialValue: key,
                      labelText: localizations.headerKey,
                      onChanged:
                          (newKey) => viewModel.updateHeaderKey(index, newKey),
                    ),

                    const SizedBox(height: 12),

                    // Value-Feld
                    _buildTextField(
                      context: context,
                      initialValue: value,
                      labelText: localizations.headerValue,
                      onChanged:
                          (newValue) =>
                              viewModel.updateHeaderValue(index, newValue),
                    ),

                    if (index < viewModel.customHeaders.length - 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Divider(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      )
                    else
                      const SizedBox(height: 8),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }

  /// Textfield
  Widget _buildTextField({
    required BuildContext context,
    String? initialValue,
    required String labelText,
    IconData? prefixIcon,
    String? hintText,
    bool obscureText = false,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      initialValue: initialValue,
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
}
