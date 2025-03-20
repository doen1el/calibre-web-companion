import 'dart:convert';
import 'package:calibre_web_companion/models/book_recommendation_model.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class BookRecommendationService {
  final Logger logger = Logger();
  final String baseUrl = 'https://meetnewbooks.com';
  final String dataParam = 'SFqzWJeqpTBU_LlOMxm5V';

  /// Search for a book by title
  ///
  /// Parameters:
  ///
  /// - `title`: String
  Future<List<BookSearchResult>> searchBook(String title) async {
    try {
      final url =
          'https://service.findbooktoread.com//books/booksearch?q=${Uri.encodeComponent(title)}';
      logger.i("Sending request to $url");
      final response = await http.get(Uri.parse(url));

      logger.d("Response: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => BookSearchResult.fromJson(item)).toList();
      } else {
        logger.e('Error searching book: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      logger.e('Exception searching book: $e');
      return [];
    }
  }

  /// Get recommendations for a book
  ///
  /// Parameters:
  ///
  /// - `book`: BookSearchResult
  Future<List<BookRecommendation>> getRecommendations(
    BookSearchResult book,
  ) async {
    if (book.bookId == null || book.idWithTitleSuffix == null) {
      return [];
    }

    try {
      final url =
          '$baseUrl/_next/data/$dataParam/suggest-book/${book.idWithTitleSuffix}.json';

      logger.i('Sending request to $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final books = data['pageProps']['data']['books'] as List;

        return books
            .map(
              (bookData) => BookRecommendation.fromJson(
                bookData,
                sourceBookId: book.bookId!,
                sourceBookTitle: book.shortTitle ?? book.line1 ?? 'Unknown',
              ),
            )
            .toList();
      } else {
        logger.e('Error getting recommendations: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      logger.e('Exception getting recommendations: $e');
      return [];
    }
  }
}
