import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:calibre_web_companion/models/book_recommendation_model.dart';
import 'package:logger/logger.dart';

class OpenLibraryRecommendationService {
  final Logger logger = Logger();
  final String _baseUrl = 'https://openlibrary.org';

  /// Sucht nach Büchern mit dem angegebenen Titel
  Future<List<BookSearchResult>> searchBook(String title, String author) async {
    try {
      final encodedQuery = Uri.encodeComponent('$title $author');
      final url = '$_baseUrl/search.json?q=$encodedQuery&limit=10';
      logger.d('Searching for book: $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['num_found'] > 0 && data['docs'].isNotEmpty) {
          List<BookSearchResult> results = [];

          for (var doc in data['docs']) {
            results.add(BookSearchResult.fromOpenLibrary(doc));
          }

          // Sortiere nach Score, falls verfügbar
          if (results.first.score != null) {
            results.sort((a, b) => (b.score ?? 0).compareTo(a.score ?? 0));
          }

          return results;
        }
      }

      logger.i('No books found for title: $title');
      return [];
    } catch (e) {
      logger.e('Error searching for book: $e');
      return [];
    }
  }

  /// Holt Empfehlungen für ein bestimmtes Buch
  Future<List<BookRecommendation>> getRecommendations(
    BookSearchResult book,
  ) async {
    try {
      // Extrahiere den Work-Key ohne führenden Slash
      String workKey = book.key;
      if (workKey.startsWith('/')) {
        workKey = workKey.substring(1);
      }

      // Hole die Subjects des Buches
      final subjects = await getBookSubjects(workKey);

      if (subjects.isEmpty) {
        logger.w('No subjects found for book: ${book.line1}');
        return [];
      }

      logger.i('Found ${subjects.length} subjects for book: ${book.line1}');

      // Finde ähnliche Bücher basierend auf den Subjects
      final recommendations = await findBooksBySubjects(
        subjects,
        limit: 20,
        excludeTitles: [book.line1], // Ausschließen des Originalbuches
        sourceBookTitle: book.line1,
      );

      return recommendations;
    } catch (e) {
      logger.e('Error getting recommendations: $e');
      return [];
    }
  }

  /// Holt die Subjects/Kategorien eines Buches
  Future<List<String>> getBookSubjects(String key) async {
    try {
      final url = '$_baseUrl/$key.json';
      logger.d('Getting book details: $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<String> allSubjects = [];

        // Sammle alle Arten von Subjects
        if (data.containsKey('subjects')) {
          allSubjects.addAll(List<String>.from(data['subjects']));
        }

        if (data.containsKey('subject_places')) {
          allSubjects.addAll(List<String>.from(data['subject_places']));
        }

        if (data.containsKey('subject_times')) {
          allSubjects.addAll(List<String>.from(data['subject_times']));
        }

        if (data.containsKey('subject_people')) {
          allSubjects.addAll(List<String>.from(data['subject_people']));
        }

        return allSubjects;
      } else {
        logger.e('Open Library API error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      logger.e('Error getting book subjects: $e');
      return [];
    }
  }

  /// Findet Bücher basierend auf mehreren Subjects mit Fokus auf höherer Übereinstimmung
  /// Findet Bücher basierend auf mehreren Subjects mit Fokus auf höherer Übereinstimmung
  Future<List<BookRecommendation>> findBooksBySubjects(
    List<String> subjects, {
    int limit = 30,
    List<String> excludeTitles = const [],
    String sourceBookTitle = 'Based on your reading history',
  }) async {
    if (subjects.isEmpty) return [];

    logger.i('Finding books with ${subjects.length} original subjects');

    // Liste zu allgemeiner Subjects, die gefiltert werden sollten
    final genericSubjects = [
      // Grundlegende Genres
      'fiction',
      'novel',
      'novels',
      'nonfiction',
      'literature',
      'science fiction',
      'sci-fi', // Kurzform hinzugefügt
      'fantasy',
      'adventure',
      'thriller',
      'mystery',
      'romance',
      'bestseller',
      'classic',
      'classics',
      'biography',
      'autobiography',
      'memoir',
      'history',
      'contemporary',
      'suspense',

      // Zielgruppenkategorien
      'juvenile fiction',
      'young adult',
      'children',
      'children\'s books',
      'juvenile literature',

      // OpenLibrary spezifische Tags
      'accessible book',
      'protected daisy',
      'overdrive',
      'large type books',
      'in library',
      'general', // Zu allgemein
      'spanish language materials', // Sprachbezogen
      'ficción', // Fremdsprachiges "Fiction"
    ];

    // Erweiterte Filterfunktion für generische und problematische Subjects
    bool shouldFilterSubject(String subject) {
      final lowerSubject = subject.toLowerCase();

      // 1. Prüfe auf generischen Subject
      if (genericSubjects.contains(lowerSubject)) {
        return true;
      }

      // 2. Prüfe speziell auf "Reading Level-Grade X" Muster
      if (lowerSubject.startsWith('reading level-grade ')) {
        return true;
      }

      // 3. Prüfe auf NYT Bestseller Tags
      if (lowerSubject.startsWith('nyt:') ||
          lowerSubject.contains('new york times bestseller') ||
          lowerSubject.contains('bestseller')) {
        return true;
      }

      // 4. Prüfe auf Kategorien mit Slash-Struktur (z.B. FICTION / Science Fiction / General)
      if (lowerSubject.contains(' / ') ||
          (lowerSubject.contains('/') &&
              lowerSubject.toUpperCase() == subject)) {
        return true;
      }

      // 5. Prüfe auf zu kurze generische Begriffe
      if (lowerSubject.length <= 3) {
        return true;
      }

      // 6. Prüfe auf Sprachen und Sprachmaterialien
      if (lowerSubject.contains('language materials') ||
          lowerSubject.endsWith(' language')) {
        return true;
      }

      return false;
    }

    // Filtere problematische Subjects aus
    List<String> specificSubjects =
        subjects.where((subject) => !shouldFilterSubject(subject)).toList();

    // Zusätzliches Logging, um die gefilterten Subjects zu sehen
    logger.i('Original subjects: ${subjects.join(", ")}');
    logger.i('Filtered subjects: ${specificSubjects.join(", ")}');

    // Sammle alle gefundenen Werke und ihre Subjects
    final allWorks = <String, Map<String, dynamic>>{};
    final workSubjects = <String, List<String>>{};
    final processedSubjects = <String>{};

    // Bereinige und entferne komplexe Subjects mit Kommas oder Sonderzeichen
    List<String> cleanSubjects =
        specificSubjects
            .where(
              (subject) =>
                  !subject.contains(',') &&
                  !subject.contains('&') &&
                  !subject.contains('(') &&
                  subject.length > 2,
            )
            .toList();

    if (cleanSubjects.isEmpty) {
      // Fallback: Versuche eine einfachere Version der Subjects
      cleanSubjects =
          specificSubjects
              .map((s) => s.split(',').first.trim())
              .where((s) => s.length > 2)
              .toList();
    }

    // Log vor der Begrenzung
    logger.i('Clean subjects before limit: ${cleanSubjects.join(", ")}');

    // Beschränke die Anzahl der Subjects, aber nehme mehr für bessere Übereinstimmung
    List<String> limitedSubjects =
        cleanSubjects.length > 12
            ? cleanSubjects.sublist(0, 12)
            : cleanSubjects;

    logger.i('Using these subjects for search: ${limitedSubjects.join(", ")}');

    // Zuerst: Sammle potenzielle Bücher für alle Subjects
    for (var subject in limitedSubjects) {
      if (processedSubjects.contains(subject.toLowerCase())) continue;
      processedSubjects.add(subject.toLowerCase());

      try {
        // WICHTIG: Verwende lowercase für Subjects in der URL
        final encodedSubject = Uri.encodeComponent(subject.toLowerCase());
        final url = '$_baseUrl/subjects/${encodedSubject}.json?limit=20';
        logger.d('Searching books for subject: $url');

        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          try {
            final data = json.decode(response.body);

            if (data.containsKey('works') && data['works'].isNotEmpty) {
              logger.d(
                'Found ${data['works'].length} books for subject "$subject"',
              );

              for (var work in data['works']) {
                final key = work['key'] as String;

                // Speichere das Werk, falls noch nicht vorhanden
                if (!allWorks.containsKey(key)) {
                  allWorks[key] = work;

                  // Initialisiere die Subject-Liste für dieses Werk
                  workSubjects[key] = [];
                }

                // Merke uns, dass dieses Werk das aktuelle Subject hat
                workSubjects[key]!.add(subject);
              }
            }
          } catch (e) {
            logger.w('JSON parsing error for subject $subject: $e');
          }
        } else {
          logger.w('API error for subject $subject: ${response.statusCode}');
        }
      } catch (e) {
        logger.w('Error finding books for subject $subject: $e');
      }
    }

    logger.i('Found ${allWorks.length} potential books across all subjects');

    // Zweiter Schritt: Sortiere nach Anzahl übereinstimmender Subjects und verarbeite
    List<MapEntry<String, List<String>>> sortedWorks =
        workSubjects.entries.toList()
          ..sort((a, b) => b.value.length.compareTo(a.value.length));

    // Mindestanzahl an Subjects für eine gute Empfehlung
    const minSubjectMatches = 3; // Start mit 2, aber wir bevorzugen mehr

    final recommendations = <BookRecommendation>[];
    final processedKeys = <String>{};

    // Verarbeite Werke mit mindestens minSubjectMatches
    for (var entry in sortedWorks) {
      final key = entry.key;
      final matchingSubjects = entry.value;

      // Überspringen, wenn nicht genügend Übereinstimmungen
      if (matchingSubjects.length < minSubjectMatches) continue;

      // Überspringen, wenn bereits verarbeitet
      if (processedKeys.contains(key)) continue;
      processedKeys.add(key);

      // Genug Empfehlungen gesammelt?
      if (recommendations.length >= limit) break;

      final work = allWorks[key]!;
      final title = work['title'] ?? 'Unknown Title';

      // Überprüfe, ob das Buch bereits gelesen wurde
      bool alreadyRead = excludeTitles.any(
        (t) => title.toLowerCase() == t.toLowerCase(),
      );
      if (alreadyRead) continue;

      // Hole alle Subjects des Buches (für detailliertere Matches und Anzeige)
      final bookSubjects = await getBookSubjects(key);

      // Filtere generische Subjects aus den anzuzeigenden Subjects
      final displaySubjects =
          bookSubjects
              .where((s) => !genericSubjects.contains(s.toLowerCase()))
              .toList();

      // Bestimme Cover-URL (wenn verfügbar)
      String coverUrl = '';
      if (work.containsKey('cover_id')) {
        coverUrl =
            'https://covers.openlibrary.org/b/id/${work['cover_id']}-M.jpg';
      } else if (work.containsKey('cover_edition_key')) {
        coverUrl =
            'https://covers.openlibrary.org/b/olid/${work['cover_edition_key']}-M.jpg';
      }

      // Bestimme Autoren
      List<String> authors = [];
      if (work.containsKey('authors')) {
        for (var author in work['authors']) {
          if (author.containsKey('name')) {
            authors.add(author['name']);
          }
        }
      }

      // Holen der Beschreibung (falls vorhanden)
      List<String> about = ['No description available.'];
      try {
        // Optionaler zusätzlicher API-Aufruf für die vollständige Beschreibung
        final workUrl = '$_baseUrl$key.json';
        final workResponse = await http.get(Uri.parse(workUrl));

        if (workResponse.statusCode == 200) {
          final workData = json.decode(workResponse.body);

          if (workData.containsKey('description')) {
            if (workData['description'] is String) {
              about = [workData['description']];
            } else if (workData['description'] is Map &&
                workData['description'].containsKey('value')) {
              about = [workData['description']['value']];
            }
          }
        }
      } catch (e) {
        // Fehler beim Holen der Beschreibung, Standard-Beschreibung beibehalten
        logger.w('Error fetching description for $key: $e');
      }

      recommendations.add(
        BookRecommendation(
          id: recommendations.length,
          title: title,
          author: authors.isNotEmpty ? authors : ['Unknown'],
          about: about,
          coverUrl: coverUrl,
          reactions:
              displaySubjects.isNotEmpty ? displaySubjects : bookSubjects,
          matchCount: matchingSubjects.length,
          sourceBookTitle: sourceBookTitle,
        ),
      );
    }

    // Wenn wir zu wenig Empfehlungen haben, versuchen wir es mit niedrigeren Anforderungen
    if (recommendations.length < limit / 2) {
      logger.i(
        'Not enough recommendations (${recommendations.length}), trying with lower match threshold',
      );

      // Verarbeite die verbleibenden Werke mit nur einem Match
      for (var entry in sortedWorks) {
        final key = entry.key;
        final matchingSubjects = entry.value;

        if (processedKeys.contains(key)) continue;
        if (recommendations.length >= limit) break;

        processedKeys.add(key);

        final work = allWorks[key]!;
        final title = work['title'] ?? 'Unknown Title';

        // Überprüfe, ob das Buch bereits gelesen wurde
        bool alreadyRead = excludeTitles.any(
          (t) => title.toLowerCase() == t.toLowerCase(),
        );
        if (alreadyRead) continue;

        // Rest der Buchverarbeitung wie oben...
        // [Der Code ist der gleiche wie im ersten Teil]

        // Hole alle Subjects des Buches (für detailliertere Matches und Anzeige)
        final bookSubjects = await getBookSubjects(key);

        // Filtere generische Subjects aus den anzuzeigenden Subjects
        final displaySubjects =
            bookSubjects
                .where((s) => !genericSubjects.contains(s.toLowerCase()))
                .toList();

        // Bestimme Cover-URL (wenn verfügbar)
        String coverUrl = '';
        if (work.containsKey('cover_id')) {
          coverUrl =
              'https://covers.openlibrary.org/b/id/${work['cover_id']}-M.jpg';
        } else if (work.containsKey('cover_edition_key')) {
          coverUrl =
              'https://covers.openlibrary.org/b/olid/${work['cover_edition_key']}-M.jpg';
        }

        // Bestimme Autoren
        List<String> authors = [];
        if (work.containsKey('authors')) {
          for (var author in work['authors']) {
            if (author.containsKey('name')) {
              authors.add(author['name']);
            }
          }
        }

        // Vereinfachte Beschreibungsermittlung für Fallback-Bücher
        List<String> about = ['No description available.'];

        recommendations.add(
          BookRecommendation(
            id: recommendations.length,
            title: title,
            author: authors.isNotEmpty ? authors : ['Unknown'],
            about: about,
            coverUrl: coverUrl,
            reactions:
                displaySubjects.isNotEmpty ? displaySubjects : bookSubjects,
            matchCount: matchingSubjects.length,
            sourceBookTitle: sourceBookTitle,
          ),
        );
      }
    }

    // Sortiere nach Anzahl übereinstimmender Subjects
    recommendations.sort((a, b) => b.matchCount.compareTo(a.matchCount));

    logger.i('Returning ${recommendations.length} recommendations');
    return recommendations.take(limit).toList();
  }

  /// Hilfsmethode zum Extrahieren von Clean-Subjects aus einem String
  List<String> extractCleanSubjects(String subject) {
    return subject
        .split(RegExp(r'[,&()]'))
        .map((s) => s.trim())
        .where((s) => s.length > 2)
        .toList();
  }
}
