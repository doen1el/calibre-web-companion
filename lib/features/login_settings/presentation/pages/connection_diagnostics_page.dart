import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:calibre_web_companion/core/services/api_service.dart';
import 'package:calibre_web_companion/core/services/connection_diagnostics.dart';
import 'package:calibre_web_companion/core/services/snackbar.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/shared/utils/status_colors.dart';

class ConnectionDiagnosticsPage extends StatefulWidget {
  const ConnectionDiagnosticsPage({super.key});

  @override
  State<ConnectionDiagnosticsPage> createState() =>
      _ConnectionDiagnosticsPageState();
}

class _ConnectionDiagnosticsPageState extends State<ConnectionDiagnosticsPage> {
  bool _isRunning = false;
  List<DiagnosticResult> _results = const [];

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() => _isRunning = true);
    try {
      final results = await ApiService().runConnectionDiagnostics();
      if (!mounted) return;
      setState(() {
        _results = results;
        _isRunning = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRunning = false);
      context.showSnackBar(
        '${AppLocalizations.of(context)!.diagnosticsFailed}: $e',
        isError: true,
      );
    }
  }

  String _buildReport() {
    final buffer = StringBuffer('Connection diagnostics\n');
    buffer.writeln('Base URL: ${ApiService().getBaseUrl()}');
    buffer.writeln('---');
    for (final r in _results) {
      buffer.writeln(r.toReportLine());
    }
    return buffer.toString();
  }

  DiagnosticResult? _resultFor(DiagnosticProbeId id) {
    for (final r in _results) {
      if (r.id == id) return r;
    }
    return null;
  }

  bool _looksLikeStockCalibre() {
    final root = _resultFor(DiagnosticProbeId.serverReachable);
    final ajax = _resultFor(DiagnosticProbeId.bookList);
    final stats = _resultFor(DiagnosticProbeId.opdsStats);
    if (root == null || ajax == null || stats == null) return false;
    return root.verdict == ProbeVerdict.ok &&
        ajax.statusCode == 404 &&
        stats.statusCode == 404;
  }

  String? _interpretation(AppLocalizations l) {
    final ajax = _resultFor(DiagnosticProbeId.bookList);
    if (ajax == null) return null;

    if (_looksLikeStockCalibre()) {
      return l.diagHintStockCalibre;
    }

    switch (ajax.verdict) {
      case ProbeVerdict.ok:
        return l.diagHintOk;
      case ProbeVerdict.redirect:
      case ProbeVerdict.loginPage:
        return l.diagHintBlocked;
      case ProbeVerdict.authRequired:
        return l.diagHintAuth;
      case ProbeVerdict.serverError:
        return l.diagHintServerError;
      case ProbeVerdict.networkError:
      case ProbeVerdict.empty:
        return l.diagHintUnreachable;
    }
  }

  String _probeTitle(DiagnosticProbeId id, AppLocalizations l) {
    switch (id) {
      case DiagnosticProbeId.serverReachable:
        return l.diagProbeServerReachable;
      case DiagnosticProbeId.bookList:
        return l.diagProbeBookList;
      case DiagnosticProbeId.opdsFeed:
        return l.diagProbeOpdsFeed;
      case DiagnosticProbeId.opdsStats:
        return l.diagProbeOpdsStats;
      case DiagnosticProbeId.coverImage:
        return l.diagProbeCoverImage;
    }
  }

  Color _verdictColor(ProbeVerdict v, BuildContext context) {
    switch (v) {
      case ProbeVerdict.ok:
        return StatusColors.success(context);
      case ProbeVerdict.loginPage:
      case ProbeVerdict.redirect:
      case ProbeVerdict.authRequired:
        return StatusColors.warning(context);
      case ProbeVerdict.serverError:
      case ProbeVerdict.networkError:
        return StatusColors.error(context);
      case ProbeVerdict.empty:
        return StatusColors.neutral(context);
    }
  }

  IconData _verdictIcon(ProbeVerdict v) {
    switch (v) {
      case ProbeVerdict.ok:
        return Icons.check_circle_rounded;
      case ProbeVerdict.loginPage:
        return Icons.html_rounded;
      case ProbeVerdict.redirect:
        return Icons.alt_route_rounded;
      case ProbeVerdict.authRequired:
        return Icons.lock_rounded;
      case ProbeVerdict.serverError:
        return Icons.dns_rounded;
      case ProbeVerdict.networkError:
        return Icons.error_outline_rounded;
      case ProbeVerdict.empty:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.connectionDiagnostics),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l.diagnosticsRerun,
            onPressed: _isRunning ? null : _run,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isRunning) const LinearProgressIndicator(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(
                    l.connectionDiagnosticsIntro,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (_results.isNotEmpty) ...[
                  _buildSectionTitle(context, l.diagnosticsEndpoints),
                  ..._results.map((r) => _buildResultCard(context, r, l)),
                  _buildInterpretationCard(context, l),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Center(
                      child: ElevatedButton.icon(
                        onPressed: _copyReport,
                        icon: const Icon(Icons.copy_rounded),
                        label: Text(l.diagnosticsCopyReport),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyReport() async {
    final l = AppLocalizations.of(context)!;
    await Clipboard.setData(ClipboardData(text: _buildReport()));
    if (!mounted) return;
    context.showSnackBar(l.diagnosticsReportCopied, isError: false);
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }

  Widget _buildResultCard(
    BuildContext context,
    DiagnosticResult r,
    AppLocalizations l,
  ) {
    final color = _verdictColor(r.verdict, context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_verdictIcon(r.verdict), size: 28, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _probeTitle(r.id, l),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    r.path,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    r.detail,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (r.redirectLocation != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '→ ${r.redirectLocation}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterpretationCard(BuildContext context, AppLocalizations l) {
    final hint = _interpretation(l);
    if (hint == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      elevation: 0,
      color: scheme.secondaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.lightbulb_outline_rounded,
              color: scheme.onSecondaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hint,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
