import 'package:calibre_web_companion/view_models/login_settings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LoginSettings extends StatefulWidget {
  const LoginSettings({super.key});

  @override
  LoginSettingsState createState() => LoginSettingsState();
}

class LoginSettingsState extends State<LoginSettings> {
  @override
  void initState() {
    super.initState();
    Provider.of<LoginSettingsViewModel>(context, listen: false).loadHeaders();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LoginSettingsViewModel>();
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(localizations.connectionSettings)),
      body:
          viewModel.isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HTTP Header Section
                    _buildSectionTitle(
                      context,
                      localizations.costumHttpPHeader,
                    ),
                    _buildHeadersCard(context, viewModel, localizations),

                    // Add Header Button
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
  }

  /// Build a section title with the same style as SettingsView
  ///
  /// Parameters:
  ///
  /// - `context`: The BuildContext
  /// - `title`: The title to display
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
  ///
  /// Parameters:
  ///
  /// - `context`: The BuildContext
  /// - `viewModel`: The LoginSettingsViewModel
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
  ///
  /// Parameters:
  ///
  /// - `context`: The BuildContext
  /// - `initialValue`: The initial value of the text field
  /// - `labelText`: The label text of the text field
  /// - `prefixIcon`: The icon to display before the text field
  /// - `hintText`: The hint text of the text field
  /// - `obscureText`: Whether the text should be obscured
  /// - `onChanged`: The function to call when the text changes
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
