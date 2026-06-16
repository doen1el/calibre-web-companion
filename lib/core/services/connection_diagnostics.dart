enum ProbeVerdict {
  ok,
  loginPage,
  redirect,
  authRequired,
  serverError,
  networkError,
  empty,
}

enum DiagnosticProbeId {
  serverReachable,
  bookList,
  opdsFeed,
  opdsStats,
  coverImage,
}

class DiagnosticResult {
  final DiagnosticProbeId id;
  final String label;
  final String path;
  final int? statusCode;
  final String? redirectLocation;
  final String? contentType;
  final ProbeVerdict verdict;
  final String detail;

  const DiagnosticResult({
    required this.id,
    required this.label,
    required this.path,
    required this.verdict,
    required this.detail,
    this.statusCode,
    this.redirectLocation,
    this.contentType,
  });

  String toReportLine() {
    final code = statusCode != null ? ' [$statusCode]' : '';
    final ct = contentType != null ? ' ($contentType)' : '';
    final buffer = StringBuffer('${verdict.symbol} $label — $path$code$ct');
    if (redirectLocation != null) {
      buffer.write('\n      -> redirect: $redirectLocation');
    }
    return buffer.toString();
  }
}

extension ProbeVerdictReport on ProbeVerdict {
  String get symbol {
    switch (this) {
      case ProbeVerdict.ok:
        return 'OK';
      case ProbeVerdict.loginPage:
        return 'HTML';
      case ProbeVerdict.redirect:
        return 'RDIR';
      case ProbeVerdict.authRequired:
        return 'AUTH';
      case ProbeVerdict.serverError:
        return '5xx ';
      case ProbeVerdict.networkError:
        return 'FAIL';
      case ProbeVerdict.empty:
        return 'EMPT';
    }
  }
}
