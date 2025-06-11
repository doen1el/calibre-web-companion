import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GithubIssueDialogViewModel extends ChangeNotifier {
  // State management
  bool _isSubmitting = false;
  String? _errorMessage;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController bodyController = TextEditingController();

  // API data
  final String token;
  final String owner;
  final String repo;

  // Getters
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  bool get hasTitle => titleController.text.trim().isNotEmpty;

  // Constructor
  GithubIssueDialogViewModel({
    required this.token,
    required this.owner,
    required this.repo,
    String initialTitle = '',
    String initialBody = '',
  }) {
    titleController.text = initialTitle;
    bodyController.text = initialBody;
  }

  // Cleanup
  @override
  void dispose() {
    titleController.dispose();
    bodyController.dispose();
    super.dispose();
  }

  // Reset error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Validate title
  void validateTitle() {
    if (!hasTitle) {
      _errorMessage = 'Title cannot be empty';
      notifyListeners();
    } else {
      clearError();
    }
  }

  // Submit issue to GitHub
  Future<Map<String, dynamic>?> submitIssue() async {
    // Validate title
    if (!hasTitle) {
      _errorMessage = 'Title cannot be empty';
      notifyListeners();
      return null;
    }

    // Begin submission
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('https://api.github.com/repos/$owner/$repo/issues'),
        headers: {
          'Authorization': 'token $token',
          'Accept': 'application/vnd.github.v3+json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'title': titleController.text,
          'body': bodyController.text,
        }),
      );

      // Handle response
      if (response.statusCode == 201) {
        // Success case
        _isSubmitting = false;
        notifyListeners();
        return jsonDecode(response.body);
      } else {
        // Error case with status code
        throw Exception(
          'Failed to create issue: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      // Handle errors
      _errorMessage = e.toString();
      _isSubmitting = false;
      notifyListeners();
      return null;
    }
  }
}
