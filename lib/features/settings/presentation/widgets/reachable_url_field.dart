import 'dart:async';

import 'package:flutter/material.dart';

import 'package:calibre_web_companion/shared/utils/status_colors.dart';

enum UrlFieldStatus { idle, checking, ok, authRequired, error }

class ReachableUrlField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;

  final Future<UrlFieldStatus> Function(String url) check;

  final ValueChanged<String>? onChanged;

  final void Function(String url, UrlFieldStatus status)? onResult;

  final Duration debounce;

  const ReachableUrlField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.check,
    this.onChanged,
    this.onResult,
    this.prefixIcon = Icons.link,
    this.debounce = const Duration(milliseconds: 600),
  });

  @override
  State<ReachableUrlField> createState() => _ReachableUrlFieldState();
}

class _ReachableUrlFieldState extends State<ReachableUrlField> {
  Timer? _debounce;
  UrlFieldStatus _status = UrlFieldStatus.idle;
  int _checkSeq = 0;

  @override
  void initState() {
    super.initState();
    if (widget.controller.text.trim().isNotEmpty) {
      _runCheck(widget.controller.text);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    widget.onChanged?.call(value);
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() => _status = UrlFieldStatus.idle);
      return;
    }
    setState(() => _status = UrlFieldStatus.checking);
    _debounce = Timer(widget.debounce, () => _runCheck(value));
  }

  Future<void> _runCheck(String value) async {
    final seq = ++_checkSeq;
    if (mounted) setState(() => _status = UrlFieldStatus.checking);
    final status = await widget.check(value.trim());
    if (!mounted || seq != _checkSeq) return;
    setState(() => _status = status);
    widget.onResult?.call(value.trim(), status);
  }

  Widget? _suffix() {
    switch (_status) {
      case UrlFieldStatus.checking:
        return const Padding(
          padding: EdgeInsets.all(12),
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      case UrlFieldStatus.ok:
      case UrlFieldStatus.authRequired:
        return Icon(
          Icons.check_circle_rounded,
          color: StatusColors.success(context),
        );
      case UrlFieldStatus.error:
        return Icon(
          Icons.error_outline_rounded,
          color: StatusColors.error(context),
        );
      case UrlFieldStatus.idle:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      onChanged: _onChanged,
      keyboardType: TextInputType.url,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon: Icon(widget.prefixIcon),
        suffixIcon: _suffix(),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 14.0,
        ),
      ),
    );
  }
}
