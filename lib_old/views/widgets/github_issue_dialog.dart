import 'package:flutter/material.dart';
import '../../view_models/github_issue_dialog_view_model.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class GithubIssueDialog extends StatelessWidget {
  final String token;
  final String owner;
  final String repo;
  final String initialTitle;
  final String initialBody;

  const GithubIssueDialog({
    super.key,
    required this.token,
    required this.owner,
    required this.repo,
    this.initialTitle = '',
    this.initialBody = '',
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (context) => GithubIssueDialogViewModel(
            token: token,
            owner: owner,
            repo: repo,
            initialTitle: initialTitle,
            initialBody: initialBody,
          ),
      child: _GithubIssueDialogContent(),
    );
  }
}

class _GithubIssueDialogContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GithubIssueDialogViewModel>();
    final localizations = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              localizations.reportIssue,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Title field
            TextField(
              controller: viewModel.titleController,
              decoration: InputDecoration(
                labelText: localizations.title,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                errorText:
                    viewModel.errorMessage != null && !viewModel.hasTitle
                        ? localizations.required
                        : null,
              ),
              maxLength: 100,
              onChanged: (_) => viewModel.clearError(),
            ),
            const SizedBox(height: 12),

            // Description field
            TextField(
              controller: viewModel.bodyController,
              decoration: InputDecoration(
                labelText: localizations.description,
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              minLines: 5,
              maxLines: 10,
            ),

            // Error message
            if (viewModel.errorMessage != null && viewModel.hasTitle)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  viewModel.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      viewModel.isSubmitting
                          ? null
                          : () => Navigator.pop(context),
                  child: Text(localizations.cancel),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed:
                      viewModel.isSubmitting
                          ? null
                          : () async {
                            final result = await viewModel.submitIssue();
                            if (result != null && context.mounted) {
                              Navigator.pop(context, result);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Issue submitted successfully!',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                  child:
                      viewModel.isSubmitting
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
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
