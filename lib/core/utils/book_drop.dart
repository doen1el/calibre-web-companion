// BookDrop (https://github.com/eitan12345om/book-drop) is the successor of
// send2ereader, whose public instance send.djazz.se has been shut down.
const String defaultBookDropUrl = 'https://bookdrop.cc';

// Saved settings may still point at the dead send2ereader instance.
String migrateBookDropUrl(String? url) {
  final trimmed = url?.trim() ?? '';
  if (trimmed.isEmpty) return defaultBookDropUrl;
  final host = Uri.tryParse(trimmed)?.host.toLowerCase() ?? '';
  if (host == 'send.djazz.se') return defaultBookDropUrl;
  return trimmed;
}

String _stripTrailingSlash(String url) =>
    url.endsWith('/') ? url.substring(0, url.length - 1) : url;

String bookDropUploadUrl(String baseUrl) =>
    '${_stripTrailingSlash(baseUrl)}/upload';

// The page the e-reader opens to get its key; works even when BookDrop
// doesn't recognize the e-reader's user agent on `/`.
String bookDropReceiveUrl(String baseUrl) =>
    '${_stripTrailingSlash(baseUrl)}/receive';
