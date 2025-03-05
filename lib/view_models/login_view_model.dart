import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:html/parser.dart' as parser;
import 'dart:convert';

class LoginViewModel extends ChangeNotifier {
  Logger logger = Logger();
  bool isLoading = false;

  Future<bool> login(String username, String password, String baseUrl) async {
    isLoading = true;
    final client = http.Client();
    try {
      final initialResponse = await client.get(Uri.parse('$baseUrl/login'));

      String? cookies = initialResponse.headers['set-cookie'];

      var document = parser.parse(initialResponse.body);
      var csrfToken =
          document
              .querySelector('input[name="csrf_token"]')
              ?.attributes['value'];

      final response = await client.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          if (cookies != null) 'Cookie': cookies,
        },
        body: {
          'username': username,
          'password': password,
          'remember_me': 'on',
          'csrf_token': csrfToken,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 302) {
        if (response.headers.containsKey('set-cookie')) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'calibre_web_session',
            response.headers['set-cookie']!,
          );
        }

        logger.i('Login was successful: ${response.statusCode}');

        return !response.body.contains('login-form') ||
            response.headers['location']?.contains('index') == true;
      }

      logger.e('Login failed: ${response.statusCode}');

      return false;
    } catch (e) {
      logger.e("Error during loging: $e");
      return false;
    } finally {
      isLoading = false;
      client.close();
    }
  }

  // Future<Map<String, dynamic>> fetchBooks() async {
  //   logger.i('Fetching books');
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     final cookie = prefs.getString('calibre_web_session');

  //     if (cookie == null) {
  //       logger.w('No session cookie found. User may not be logged in');
  //       return {};
  //     }

  //     final client = http.Client();
  //     try {
  //       logger.d('Sending request to fetch books with cookie');
  //       final response = await client.get(
  //         Uri.parse('$baseUrl/ajax/listbooks'),
  //         headers: {'Cookie': cookie},
  //       );

  //       logger.i('Book list response status: ${response.statusCode}');

  //       if (response.statusCode == 200) {
  //         // Parse the response as a Map instead of a List
  //         final Map<String, dynamic> booksJson = json.decode(response.body);

  //         // Log the structure of the response to help debug
  //         logger.d('Response structure: ${booksJson.keys.join(', ')}');

  //         return booksJson;
  //       } else if (response.statusCode == 401) {
  //         logger.w('Session expired or invalid');
  //         errorMessage = 'Your session has expired. Please log in again.';
  //         notifyListeners();
  //         return {};
  //       } else {
  //         logger.e('Failed to fetch books: ${response.statusCode}');
  //         errorMessage = 'Failed to fetch books from server';
  //         notifyListeners();
  //         return {};
  //       }
  //     } finally {
  //       client.close();
  //     }
  //   } catch (e) {
  //     logger.e('Exception while fetching books: $e');
  //     errorMessage = 'Error: $e';
  //     notifyListeners();
  //     return {};
  //   }
  // }
}
