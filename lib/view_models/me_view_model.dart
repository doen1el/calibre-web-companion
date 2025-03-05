import 'dart:convert';
import 'package:calibre_web_companion/models/stats_model.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart'; // Fixed import
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class MeViewModel extends ChangeNotifier {
  Logger logger = Logger();
  bool isLoading = false;
  StatsModel? stats;
  String? errorMessage;

  Future<StatsModel> getStats() async {
    isLoading = true;
    errorMessage = null;

    try {
      // Get session cookie
      final prefs = await SharedPreferences.getInstance();
      final baseUrl = prefs.getString('base_url');
      final username = prefs.getString('username');
      final password = prefs.getString('password');

      if (baseUrl == null) {
        logger.w('No session cookie or server URL found');
        errorMessage = 'Not logged in or server URL missing';
        isLoading = false;
        return StatsModel();
      }

      // Construct the stats URL (fixed the typo)
      final url = '$baseUrl/opds/stats';

      String basicAuth =
          'Basic ${base64.encode(utf8.encode('$username:$password'))}';

      var response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': basicAuth},
      );

      logger.i('Stats response status: ${response.body}');

      if (response.statusCode == 200) {
        // Parse JSON response
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        final statsModel = StatsModel.fromJson(jsonData);

        stats = statsModel;
        isLoading = false;

        return statsModel;
      } else {
        errorMessage = 'Failed to load stats: ${response.statusCode}';
        isLoading = false;
        return StatsModel();
      }
    } catch (e) {
      logger.e('Error loading stats: $e');
      errorMessage = 'Error: $e';
      isLoading = false;
      return StatsModel();
    }
  }
}
