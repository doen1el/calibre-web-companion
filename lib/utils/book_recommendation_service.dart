import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:calibre_web_companion/models/book_recommendation_model.dart';
import 'package:logger/logger.dart';

class BookRecommendationService {
  final Logger logger = Logger();
  final String _endpoint = 'https://dbpedia.org/sparql';

  /// Searches for a book in DBpedia
  Future<Map<String, dynamic>?> findBookInDBpedia(
    String title,
    String? author,
  ) async {
    final query = '''
      PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX dbo: <http://dbpedia.org/ontology/>
      PREFIX dbp: <http://dbpedia.org/property/>
      
      SELECT DISTINCT ?book ?title ?abstract ?author WHERE {
        ?book rdf:type dbo:Book ;
              rdfs:label ?title .
        OPTIONAL { ?book dbo:abstract ?abstract . FILTER(LANG(?abstract) = "en") }
        OPTIONAL { ?book dbo:author ?authorUri . ?authorUri rdfs:label ?author . FILTER(LANG(?author) = "en") }
        
        FILTER(REGEX(?title, "${_escapeString(title)}", "i"))
        ${author != null ? 'FILTER(REGEX(?author, "${_escapeString(author)}", "i"))' : ''}
        FILTER(LANG(?title) = "en")
      }
      LIMIT 1
    ''';

    return await _executeQuery(query);
  }

  /// Gets subjects for a book
  Future<List<String>> getBookSubjects(String bookUri) async {
    final query = '''
      PREFIX dcterms: <http://purl.org/dc/terms/>
      
      SELECT DISTINCT ?subject WHERE {
        <$bookUri> dcterms:subject ?subjectUri .
        ?subjectUri rdfs:label ?subject .
        FILTER(LANG(?subject) = "en")
      }
    ''';

    final result = await _executeQuery(query);
    final subjects = <String>[];

    if (result != null && result.containsKey('results')) {
      for (var binding in result['results']['bindings']) {
        if (binding.containsKey('subject')) {
          subjects.add(binding['subject']['value']);
        }
      }
    }

    return subjects;
  }

  /// Gets all subjects from a list of books
  Future<Map<String, int>> getAllSubjects(
    List<Map<String, dynamic>> books,
  ) async {
    Map<String, int> allSubjects = {};

    for (var book in books) {
      if (book.containsKey('book')) {
        final bookUri = book['book']['value'];
        final subjects = await getBookSubjects(bookUri);

        for (var subject in subjects) {
          if (allSubjects.containsKey(subject)) {
            allSubjects[subject] = allSubjects[subject]! + 1;
          } else {
            allSubjects[subject] = 1;
          }
        }
      }
    }

    return allSubjects;
  }

  /// Gets popular book subjects from DBpedia
  Future<Map<String, int>> getPopularBookSubjects({int limit = 100}) async {
    final query = '''
      PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX dbo: <http://dbpedia.org/ontology/>
      PREFIX dcterms: <http://purl.org/dc/terms/>
      
      SELECT ?subject (COUNT(?book) as ?count) WHERE {
        ?book rdf:type dbo:Book ;
              dcterms:subject ?subjectUri .
        ?subjectUri rdfs:label ?subject .
        FILTER(LANG(?subject) = "en")
      }
      GROUP BY ?subject
      ORDER BY DESC(?count)
      LIMIT $limit
    ''';

    final result = await _executeQuery(query);
    final subjects = <String, int>{};

    if (result != null && result.containsKey('results')) {
      for (var binding in result['results']['bindings']) {
        if (binding.containsKey('subject') && binding.containsKey('count')) {
          subjects[binding['subject']['value']] = int.parse(
            binding['count']['value'],
          );
        }
      }
    }

    return subjects;
  }

  /// Finds similar books based on subjects
  Future<List<BookRecommendation>> getSimilarBooksBySubjects(
    List<String> subjects, {
    int limit = 10,
  }) async {
    if (subjects.isEmpty) return [];

    // Create FILTER conditions for each subject
    final subjectFilters = subjects
        .map(
          (s) =>
              'EXISTS { ?book dcterms:subject ?s . ?s rdfs:label ?label . FILTER(REGEX(?label, "${_escapeString(s)}", "i")) }',
        )
        .join(' || ');

    final query = '''
      PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX dbo: <http://dbpedia.org/ontology/>
      PREFIX dcterms: <http://purl.org/dc/terms/>
      
      SELECT DISTINCT ?book ?title ?abstract ?author ?authorName WHERE {
        ?book rdf:type dbo:Book ;
              rdfs:label ?title ;
              dbo:abstract ?abstract .
        OPTIONAL { ?book dbo:author ?author . ?author rdfs:label ?authorName . FILTER(LANG(?authorName) = "en") }
        
        FILTER($subjectFilters)
        FILTER(LANG(?title) = "en")
        FILTER(LANG(?abstract) = "en")
      }
      LIMIT $limit
    ''';

    final result = await _executeQuery(query);
    final recommendations = <BookRecommendation>[];

    if (result != null && result.containsKey('results')) {
      for (var binding in result['results']['bindings']) {
        recommendations.add(
          BookRecommendation(
            title: binding['title']['value'],
            author:
                binding.containsKey('authorName')
                    ? binding['authorName']['value']
                    : 'Unknown',
          ),
        );
      }
    }

    return recommendations;
  }

  /// Escape special characters for SPARQL query
  String _escapeString(String input) {
    return input.replaceAll('"', '\\"').replaceAll("'", "\\'");
  }

  /// Execute a SPARQL query against DBpedia
  Future<Map<String, dynamic>?> _executeQuery(String query) async {
    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Accept': 'application/sparql-results+json',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'query': query},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        logger.e('DBpedia query failed with status: ${response.statusCode}');
        logger.e('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      logger.e('Error querying DBpedia: $e');
      return null;
    }
  }

  /// Findet Bücher, die mehrere der angegebenen Subjects haben
  /// Findet Bücher, die mehrere der angegebenen Subjects haben
  Future<List<BookRecommendation>> findBooksByMultipleSubjects(
    List<String> subjects, {
    int minimumMatches = 3,
    List<String> excludeTitles = const [],
  }) async {
    if (subjects.isEmpty) return [];

    logger.i(
      'Finding books with ${subjects.length} subjects, minimum matches: $minimumMatches',
    );

    // Erstelle Regex-Filter für jedes Subject
    final subjectFilters = subjects
        .map((s) => 'REGEX(?matchedSubject, "${_escapeString(s)}", "i")')
        .join(' || ');

    final query = '''
    PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX dbo: <http://dbpedia.org/ontology/>
    PREFIX dcterms: <http://purl.org/dc/terms/>
    
    SELECT DISTINCT ?book ?title ?abstract ?authorName (COUNT(DISTINCT ?subjectUri) as ?matchCount) WHERE {
      # Basis-Buchinfos
      ?book rdf:type dbo:Book ;
            rdfs:label ?title .
      
      # Optionale Felder
      OPTIONAL { ?book dbo:abstract ?abstract . FILTER(LANG(?abstract) = "en") }
      OPTIONAL { ?book dbo:author ?author . ?author rdfs:label ?authorName . FILTER(LANG(?authorName) = "en") }
      
      # Subjects des Buches
      ?book dcterms:subject ?subjectUri .
      ?subjectUri rdfs:label ?matchedSubject .
      
      # Filtern nach übereinstimmenden Subjects mit Regex für Teilübereinstimmungen
      FILTER(LANG(?matchedSubject) = "en" && ($subjectFilters))
      
      # Filtern nach englischem Titel
      FILTER(LANG(?title) = "en")
      
      ${excludeTitles.isNotEmpty ? '# Ausschluss bereits gelesener Bücher\nFILTER(' + excludeTitles.map((t) => '!REGEX(?title, "${_escapeString(t)}", "i")').join(' && ') + ')' : ''}
    }
    GROUP BY ?book ?title ?abstract ?authorName
    HAVING (COUNT(DISTINCT ?subjectUri) >= $minimumMatches)
    ORDER BY DESC(?matchCount)
    LIMIT 30
  ''';

    logger.d('Executing query: $query');

    final result = await _executeQuery(query);
    final recommendations = <BookRecommendation>[];

    if (result != null && result.containsKey('results')) {
      final bindings = result['results']['bindings'];
      logger.i('Found ${bindings.length} matching books');

      for (var binding in bindings) {
        try {
          final bookUri = binding['book']['value'];
          final title = binding['title']['value'];
          final matchCount = int.parse(binding['matchCount']['value']);

          logger.i('Processing book: $title with $matchCount matches');

          // Hole alle Subjects für dieses Buch
          final bookSubjects = await getBookSubjects(bookUri);
          logger.i('Got ${bookSubjects.length} subjects for book: $title');

          recommendations.add(
            BookRecommendation(
              id: recommendations.length,
              title: title,
              author:
                  binding.containsKey('authorName')
                      ? [binding['authorName']['value']]
                      : ['Unknown'],
              about:
                  binding.containsKey('abstract')
                      ? [binding['abstract']['value']]
                      : ['No description available.'],
              reactions: bookSubjects,
              matchCount: matchCount,
              sourceBookTitle: 'Based on your reading history',
            ),
          );
        } catch (e) {
          logger.w('Error creating recommendation from binding: $e');
        }
      }
    } else {
      logger.w('No results found or error in query response');
    }

    return recommendations;
  }
}
