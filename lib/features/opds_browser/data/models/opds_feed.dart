import 'package:calibre_web_companion/core/utils/opds_entry_mapper.dart';
import 'package:calibre_web_companion/features/book_view/data/models/book_view_model.dart';
import 'package:equatable/equatable.dart';

class OpdsNavigationEntry extends Equatable {
  final String title;
  final String subtitle;
  final String url;

  const OpdsNavigationEntry({
    required this.title,
    required this.url,
    this.subtitle = '',
  });

  @override
  List<Object?> get props => [title, subtitle, url];
}

class OpdsFeed {
  final String url;
  final String title;
  final List<OpdsNavigationEntry> navigation;
  final List<BookViewModel> books;
  final String? nextUrl;

  /// Either an Atom URL template containing `{searchTerms}` or the URL of an
  /// OpenSearch description, see [searchIsTemplate].
  final String? searchHref;
  final bool searchIsTemplate;

  const OpdsFeed({
    required this.url,
    this.title = '',
    this.navigation = const [],
    this.books = const [],
    this.nextUrl,
    this.searchHref,
    this.searchIsTemplate = false,
  });

  factory OpdsFeed.fromJson(Map<String, dynamic> json, String url) {
    final feedUri = Uri.parse(url);
    final feed = json['feed'];
    if (feed is! Map) return OpdsFeed(url: url);

    String? nextUrl;
    String? searchTemplate;
    String? searchDescription;
    for (final link in _asList(feed['link'])) {
      if (link is! Map) continue;
      final rel = link['_rel']?.toString();
      final href = link['_href']?.toString();
      final type = link['_type']?.toString() ?? '';
      if (href == null || href.isEmpty) continue;

      if (rel == 'next') {
        nextUrl = feedUri.resolve(href).toString();
      } else if (rel == 'search') {
        // Resolved only once filled in: Uri would percent-encode the braces.
        if (href.contains('{searchTerms}')) {
          searchTemplate ??= href;
        } else if (type.contains('opensearchdescription')) {
          searchDescription ??= feedUri.resolve(href).toString();
        }
      }
    }

    final navigation = <OpdsNavigationEntry>[];
    final books = <BookViewModel>[];
    for (final entry in _asList(feed['entry'])) {
      if (entry is! Map) continue;
      if (_hasAcquisitionLink(entry)) {
        final book = mapOpdsEntry(entry, baseUri: feedUri);
        if (book != null) books.add(book);
      } else {
        final nav = _navigationEntry(entry, feedUri);
        if (nav != null) navigation.add(nav);
      }
    }

    return OpdsFeed(
      url: url,
      title: _text(feed['title']),
      navigation: navigation,
      books: books,
      nextUrl: nextUrl,
      searchHref: searchTemplate ?? searchDescription,
      searchIsTemplate: searchTemplate != null,
    );
  }

  // Classified per entry: Calibre-Web marks its book feeds as
  // kind=navigation too, so the feed's declared kind can't be trusted.
  static bool _hasAcquisitionLink(Map entry) {
    return _asList(entry['link']).any(
      (link) =>
          link is Map &&
          (link['_rel']?.toString() ?? '').startsWith(
            'http://opds-spec.org/acquisition',
          ),
    );
  }

  static OpdsNavigationEntry? _navigationEntry(Map entry, Uri feedUri) {
    for (final link in _asList(entry['link'])) {
      if (link is! Map) continue;
      final href = link['_href']?.toString();
      final type = link['_type']?.toString() ?? '';
      if (href == null || href.isEmpty) continue;
      if (type.isNotEmpty && !type.contains('atom+xml')) continue;

      return OpdsNavigationEntry(
        title: _text(entry['title']),
        subtitle: _text(entry['content'] ?? entry['summary']),
        url: feedUri.resolve(href).toString(),
      );
    }
    return null;
  }

  static List<dynamic> _asList(dynamic value) {
    if (value == null) return const [];
    return value is List ? value : [value];
  }

  static String _text(dynamic value) {
    if (value is Map) {
      return (value['value'] ?? value['__cdata'] ?? value['#text'] ?? '')
          .toString()
          .trim();
    }
    return value?.toString().trim() ?? '';
  }
}
