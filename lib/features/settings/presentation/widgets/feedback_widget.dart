import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:calibre_web_companion/features/settings/bloc/settings_bloc.dart';
import 'package:calibre_web_companion/features/settings/bloc/settings_event.dart';
import 'package:calibre_web_companion/features/settings/bloc/settings_state.dart';

import 'package:calibre_web_companion/core/services/snackbar.dart';

class FeedbackWidget extends StatelessWidget {
  const FeedbackWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen:
          (previous, current) => previous.appVersion != current.appVersion,
      builder: (context, state) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8.0),
            onTap: () {
              _showFeedbackDialog(context, state);
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
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
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
      },
    );
  }

  void _showFeedbackDialog(BuildContext context, SettingsState state) {
    final localizations = AppLocalizations.of(context)!;

    final titleController = TextEditingController();
    final descriptionController = TextEditingController(
      text: """
              ## Description


              ## Expected Behavior


              ## Current Behavior


              ## App Version ${state.appVersion}

              """,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(localizations.reportIssue),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  onChanged:
                      (value) => context.read<SettingsBloc>().add(
                        EnterFeedbackTitle(value),
                      ),
                  decoration: InputDecoration(
                    labelText: localizations.title,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  maxLength: 100,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  onChanged:
                      (value) => context.read<SettingsBloc>().add(
                        EnterFeedbackDescription(value),
                      ),
                  decoration: InputDecoration(
                    labelText: localizations.description,
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  minLines: 6,
                  maxLines: 10,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations.cancel),
            ),
            BlocBuilder<SettingsBloc, SettingsState>(
              builder: (context, state) {
                final isSubmitting =
                    state.feedbackStatus == SettingsFeedbackStatus.loading;

                return ElevatedButton(
                  onPressed:
                      isSubmitting
                          ? null
                          : () {
                            if (titleController.text.trim().isEmpty) {
                              context.showSnackBar(
                                localizations.titleIsRequired,
                                isError: true,
                              );
                              return;
                            }

                            if (descriptionController.text.trim().isEmpty) {
                              context.showSnackBar(
                                localizations.descriptionIsRequired,
                                isError: true,
                              );

                              return;
                            }

                            context.read<SettingsBloc>().add(SubmitFeedback());

                            Navigator.pop(context);
                          },
                  child:
                      isSubmitting
                          ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          )
                          : Text(localizations.submit),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
