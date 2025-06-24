import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:calibre_web_companion/features/settings/bloc/settings_bloc.dart';
import 'package:calibre_web_companion/features/settings/bloc/settings_event.dart';
import 'package:calibre_web_companion/features/settings/bloc/settings_state.dart';

import 'package:calibre_web_companion/features/settings/data/models/predefined_colors.dart';
import 'package:calibre_web_companion/features/settings/data/models/theme_source.dart';

class ThemeSelectorWidget extends StatelessWidget {
  const ThemeSelectorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildThemeSelector(context),
        _buildColorThemeSelector(context),
      ],
    );
  }

  Widget _buildThemeSelector(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (previous, current) => previous.themeMode != current.themeMode,
      builder: (context, state) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
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
                      state,
                    ),
                    _buildThemeOption(
                      context,
                      ThemeMode.light,
                      Icons.brightness_5,
                      localizations.lightTheme,
                      state,
                    ),
                    _buildThemeOption(
                      context,
                      ThemeMode.dark,
                      Icons.brightness_2,
                      localizations.darkTheme,
                      state,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    ThemeMode mode,
    IconData icon,
    String label,
    SettingsState state,
  ) {
    final isSelected = state.themeMode == mode;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.read<SettingsBloc>().add(SetThemeMode(mode)),
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

  Widget _buildColorThemeSelector(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen:
          (previous, current) =>
              previous.themeSource != current.themeSource ||
              previous.selectedColorKey != current.selectedColorKey,
      builder: (context, state) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
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
                      value: state.themeSource,
                      underline: Container(),
                      onChanged: (ThemeSource? newValue) {
                        if (newValue != null) {
                          context.read<SettingsBloc>().add(
                            SetThemeSource(newValue),
                          );
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

                if (state.themeSource == ThemeSource.custom) ...[
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children:
                          PredefinedColors.predefinedColors.entries.map((
                            entry,
                          ) {
                            final isSelected =
                                state.selectedColorKey == entry.key;

                            return Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: Column(
                                children: [
                                  InkWell(
                                    onTap:
                                        () => context.read<SettingsBloc>().add(
                                          SetSelectedColor(entry.key),
                                        ),
                                    borderRadius: BorderRadius.circular(30),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
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
                                                    color: entry.value
                                                        .withValues(alpha: .5),
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
                                  Text(
                                    PredefinedColors.predefinedColorNames[entry
                                        .key]!,
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ],

                if (state.themeSource == ThemeSource.system) ...[
                  const SizedBox(height: 12),
                  Text(
                    localizations.systemThemeDescription,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize:
                          Theme.of(context).textTheme.bodyMedium?.fontSize,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
