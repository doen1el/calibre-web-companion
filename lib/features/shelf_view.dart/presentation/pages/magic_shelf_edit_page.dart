import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

import 'package:calibre_web_companion/core/services/snackbar.dart';
import 'package:calibre_web_companion/core/services/api_service.dart';
import 'package:calibre_web_companion/main.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/features/book_view/data/datasources/vocabulary_remote_datasource.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/bloc/shelf_view_bloc.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/bloc/shelf_view_event.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/data/models/magic_rule_models.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/data/repositories/shelf_view_repository.dart';
import 'package:calibre_web_companion/shared/utils/status_colors.dart';

class MagicShelfEditPage extends StatefulWidget {
  final String? shelfId;
  final String? fallbackName;
  final String? fallbackIcon;

  const MagicShelfEditPage({
    super.key,
    this.shelfId,
    this.fallbackName,
    this.fallbackIcon,
  });

  @override
  State<MagicShelfEditPage> createState() => _MagicShelfEditPageState();
}

class _MagicShelfEditPageState extends State<MagicShelfEditPage> {
  final _repo = getIt<ShelfViewRepository>();
  final _nameController = TextEditingController();
  final _iconController = TextEditingController(text: '🪄');

  bool _loading = true;
  String? _loadError;
  bool _saving = false;
  bool _rulesLoadFailed = false;

  bool _koboSync = false;
  bool _isPublic = false;
  bool _canBePublic = false;
  Map<String, String> _languages = const {};
  MagicGroup _root = MagicGroup.empty();

  bool _previewing = false;
  bool? _previewSuccess;
  String _previewMessage = '';
  List<String> _previewSamples = const [];

  bool get _isEdit => widget.shelfId != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final data = await _repo.getMagicShelfFormData(shelfId: widget.shelfId);
      if (!mounted) return;
      setState(() {
        _nameController.text = data.name;
        _iconController.text = data.icon;
        _koboSync = data.koboSync;
        _isPublic = data.isPublic;
        _canBePublic = data.canBePublic;
        _languages = data.languages;
        _root = data.rules ?? MagicGroup.empty();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (_isEdit && (widget.fallbackName != null)) {
        setState(() {
          _nameController.text = widget.fallbackName ?? '';
          _iconController.text = widget.fallbackIcon ?? '🪄';
          _root = MagicGroup.empty();
          _canBePublic = true;
          _rulesLoadFailed = true;
          _loading = false;
        });
        return;
      }
      setState(() {
        _loading = false;
        _loadError = e.toString();
      });
    }
  }

  void _rebuild() => setState(() {});

  Future<void> _preview() async {
    setState(() {
      _previewing = true;
      _previewSuccess = null;
    });
    try {
      final res = await _repo.previewMagicShelf(_root.toJson());
      if (!mounted) return;
      final count = res['count'] ?? 0;
      final samples =
          (res['sample_books'] as List?)?.map((e) => e.toString()).toList() ??
          const <String>[];
      setState(() {
        _previewing = false;
        _previewSuccess = true;
        _previewMessage = '$count book(s) match these rules';
        _previewSamples = samples;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _previewing = false;
        _previewSuccess = false;
        _previewMessage = e.toString().replaceFirst('Exception: ', '');
        _previewSamples = const [];
      });
    }
  }

  Future<void> _save() async {
    final localizations = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      context.showSnackBar(localizations.shelfNameRequired, isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final rules = _root.toJson();
      final icon =
          _iconController.text.trim().isEmpty
              ? '🪄'
              : _iconController.text.trim();
      if (_isEdit) {
        await _repo.editMagicShelf(
          shelfId: widget.shelfId!,
          name: name,
          rules: rules,
          icon: icon,
          koboSync: _koboSync,
          isPublic: _isPublic,
        );
      } else {
        await _repo.createMagicShelf(
          name: name,
          rules: rules,
          icon: icon,
          koboSync: _koboSync,
          isPublic: _isPublic,
        );
      }
      if (!mounted) return;
      context.read<ShelfViewBloc>().add(const LoadShelves());
      context.showSnackBar(
        _isEdit
            ? localizations.magicShelfSaved
            : localizations.magicShelfCreated,
        isError: false,
      );
      Navigator.of(context).pop((name: name, icon: icon));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      context.showSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit
              ? localizations.editMagicShelf
              : localizations.createMagicShelf,
        ),
      ),
      body: _buildBody(localizations),
    );
  }

  Widget _buildBody(AppLocalizations localizations) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(_loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _load,
                child: Text(localizations.tryAgain),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      children: [
        if (_rulesLoadFailed) _buildRulesFailedBanner(localizations),
        _sectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNameField(localizations),
              const SizedBox(height: 16),
              _buildIconPicker(localizations),
            ],
          ),
        ),
        _sectionCard(child: _buildToggles(localizations)),
        _sectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.rules,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              _GroupEditor(
                group: _root,
                languages: _languages,
                onChanged: _rebuild,
                depth: 0,
              ),
            ],
          ),
        ),
        _buildPreviewPanel(localizations),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _previewing ? null : _preview,
                  icon:
                      _previewing
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.visibility_rounded),
                  label: Text(localizations.previewRules),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon:
                      _saving
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.save_rounded),
                  label: Text(localizations.saveShelf),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }

  Widget _buildRulesFailedBanner(AppLocalizations localizations) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: scheme.error, width: 4)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: scheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              localizations.magicRulesLoadFailed,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField(AppLocalizations localizations) {
    return TextField(
      controller: _nameController,
      maxLength: 100,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: localizations.shelfName,
        hintText: 'e.g., Recently Added, Highly Rated, Unread Sci-Fi',
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildIconPicker(AppLocalizations localizations) {
    final scheme = Theme.of(context).colorScheme;
    final icon =
        _iconController.text.trim().isEmpty
            ? '🪄'
            : _iconController.text.trim();
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Text(icon, style: const TextStyle(fontSize: 28)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.shelfIcon,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 2),
            ],
          ),
        ),
        TextButton(onPressed: _pickIcon, child: Text(localizations.change)),
      ],
    );
  }

  Future<void> _pickIcon() async {
    final scheme = Theme.of(context).colorScheme;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: scheme.surface,
      builder: (sheetContext) {
        return SizedBox(
          height: 340,
          child: EmojiPicker(
            onEmojiSelected: (category, emoji) {
              _iconController.text = emoji.emoji;
              setState(() {});
              Navigator.of(sheetContext).pop();
            },
            config: Config(
              height: 340,
              emojiViewConfig: EmojiViewConfig(
                backgroundColor: scheme.surface,
                columns: 8,
                emojiSizeMax: 28,
                buttonMode: ButtonMode.MATERIAL,
              ),
              categoryViewConfig: CategoryViewConfig(
                backgroundColor: scheme.surface,
                indicatorColor: scheme.primary,
                iconColor: scheme.onSurfaceVariant,
                iconColorSelected: scheme.primary,
                backspaceColor: scheme.primary,
                dividerColor: scheme.outlineVariant,
              ),
              bottomActionBarConfig: const BottomActionBarConfig(
                enabled: false,
              ),
              searchViewConfig: SearchViewConfig(
                backgroundColor: scheme.surfaceContainerHighest,
                buttonIconColor: scheme.onSurfaceVariant,
              ),
            ),
          ),
        );
      },
    );
    if (mounted) setState(() {});
  }

  Widget _buildToggles(AppLocalizations localizations) {
    return Column(
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _koboSync,
          onChanged: (v) => setState(() => _koboSync = v),
          title: Text(localizations.enableKoboSync),
          subtitle: Text(localizations.enableKoboSyncHint),
        ),
        if (_canBePublic)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _isPublic,
            onChanged: (v) => setState(() => _isPublic = v),
            title: Text(localizations.shareWithEveryone),
            subtitle: Text(localizations.shareWithEveryoneHint),
          ),
      ],
    );
  }

  Widget _buildPreviewPanel(AppLocalizations localizations) {
    if (_previewSuccess == null) return const SizedBox.shrink();
    final ok = _previewSuccess == true;
    final scheme = Theme.of(context).colorScheme;
    final accent =
        ok ? StatusColors.success(context) : StatusColors.error(context);

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  ok ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                  color: accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _previewMessage,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (_previewSamples.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              localizations.sampleResults,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            ..._previewSamples.map(
              (b) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      size: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(b)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GroupEditor extends StatelessWidget {
  final MagicGroup group;
  final Map<String, String> languages;
  final VoidCallback onChanged;
  final VoidCallback? onDelete;
  final int depth;

  const _GroupEditor({
    required this.group,
    required this.languages,
    required this.onChanged,
    required this.depth,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color:
            depth.isEven
                ? scheme.surfaceContainerLow
                : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: scheme.primary, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _andOrToggle(context),
              const Spacer(),
              if (onDelete != null)
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
                  tooltip: AppLocalizations.of(context)!.delete,
                  onPressed: onDelete,
                ),
            ],
          ),
          const SizedBox(height: 4),
          ...List.generate(group.children.length, (i) {
            final child = group.children[i];
            void deleteChild() {
              group.children.removeAt(i);
              onChanged();
            }

            if (child is MagicGroup) {
              return _GroupEditor(
                group: child,
                languages: languages,
                onChanged: onChanged,
                onDelete: deleteChild,
                depth: depth + 1,
              );
            }
            return _RuleEditor(
              rule: child as MagicRule,
              languages: languages,
              onChanged: onChanged,
              onDelete: deleteChild,
            );
          }),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  group.children.add(MagicRule.defaultRule());
                  onChanged();
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(AppLocalizations.of(context)!.addRule),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  group.children.add(MagicGroup.empty());
                  onChanged();
                },
                icon: const Icon(Icons.create_new_folder_outlined, size: 18),
                label: Text(AppLocalizations.of(context)!.addGroup),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _andOrToggle(BuildContext context) {
    final isAnd = group.condition == 'AND';
    return ToggleButtons(
      isSelected: [isAnd, !isAnd],
      onPressed: (i) {
        group.condition = i == 0 ? 'AND' : 'OR';
        onChanged();
      },
      borderRadius: BorderRadius.circular(8),
      constraints: const BoxConstraints(minWidth: 56, minHeight: 34),
      children: const [Text('AND'), Text('OR')],
    );
  }
}

class _RuleEditor extends StatelessWidget {
  final MagicRule rule;
  final Map<String, String> languages;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  const _RuleEditor({
    required this.rule,
    required this.languages,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final field = magicFieldById(rule.fieldId);
    final operators = operatorsForField(field);
    if (!operators.any((o) => o.id == rule.operatorId)) {
      rule.operatorId = operators.first.id;
    }
    final op = magicOperatorById(rule.operatorId);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: rule.fieldId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  items:
                      kMagicFields
                          .map(
                            (f) => DropdownMenuItem(
                              value: f.id,
                              child: Text(
                                f.label,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    rule.fieldId = v;
                    final newField = magicFieldById(v);
                    final newOps = operatorsForField(newField);
                    rule.operatorId = newOps.first.id;
                    rule.value = _defaultValueFor(newField, newOps.first);
                    onChanged();
                  },
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: scheme.error),
                tooltip: AppLocalizations.of(context)!.delete,
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: rule.operatorId,
            isExpanded: true,
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
            ),
            items:
                operators
                    .map(
                      (o) =>
                          DropdownMenuItem(value: o.id, child: Text(o.label)),
                    )
                    .toList(),
            onChanged: (v) {
              if (v == null) return;
              rule.operatorId = v;
              rule.value = _defaultValueFor(field, magicOperatorById(v));
              onChanged();
            },
          ),
          if (op.valueCount > 0) ...[
            const SizedBox(height: 8),
            _RuleValueEditor(
              field: field,
              operator: op,
              rule: rule,
              languages: languages,
              onChanged: onChanged,
            ),
          ],
        ],
      ),
    );
  }
}

dynamic _defaultValueFor(MagicField field, MagicOperator op) {
  if (op.valueCount == 0) return null;
  if (op.isList) return <dynamic>[];
  if (op.valueCount == 2) return <dynamic>[null, null];
  switch (field.input) {
    case MagicFieldInput.radio:
      return int.tryParse(field.values!.keys.first) ?? 0;
    case MagicFieldInput.select:
      if (field.id == 'rating') return 1;
      return field.values != null && field.values!.isNotEmpty
          ? field.values!.keys.first
          : '';
    case MagicFieldInput.text:
      return field.type == MagicFieldType.string ||
              field.type == MagicFieldType.date
          ? ''
          : null;
  }
}

class _RuleValueEditor extends StatelessWidget {
  final MagicField field;
  final MagicOperator operator;
  final MagicRule rule;
  final Map<String, String> languages;
  final VoidCallback onChanged;

  const _RuleValueEditor({
    required this.field,
    required this.operator,
    required this.rule,
    required this.languages,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (operator.isList) {
      final current =
          (rule.value is List)
              ? (rule.value as List).join(', ')
              : (rule.value?.toString() ?? '');
      return TextFormField(
        key: ValueKey('list-${identityHashCode(rule)}-${field.id}'),
        initialValue: current,
        decoration: InputDecoration(
          isDense: true,
          border: const OutlineInputBorder(),
          labelText: AppLocalizations.of(context)!.commaSeparatedValues,
        ),
        onChanged: (text) {
          rule.value =
              text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
        },
      );
    }

    if (operator.valueCount == 2) {
      final list = (rule.value is List) ? rule.value as List : [null, null];
      while (list.length < 2) {
        list.add(null);
      }
      rule.value = list;
      return Row(
        children: [
          Expanded(
            child: _singleInput(
              context,
              value: list[0],
              slot: 'a',
              onValue: (v) {
                list[0] = v;
                rule.value = list;
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _singleInput(
              context,
              value: list[1],
              slot: 'b',
              onValue: (v) {
                list[1] = v;
                rule.value = list;
              },
            ),
          ),
        ],
      );
    }

    return _singleInput(
      context,
      value: rule.value,
      slot: 'v',
      onValue: (v) {
        rule.value = v;
        if (field.input != MagicFieldInput.text ||
            field.type == MagicFieldType.date) {
          onChanged();
        }
      },
    );
  }

  Widget _singleInput(
    BuildContext context, {
    required dynamic value,
    required String slot,
    required ValueChanged<dynamic> onValue,
  }) {
    if (field.input == MagicFieldInput.radio) {
      final entries = field.values!.entries.toList();
      final currentKey = value?.toString();
      return Wrap(
        spacing: 8,
        children:
            entries.map((e) {
              final selected = currentKey == e.key;
              return ChoiceChip(
                label: Text(e.value),
                selected: selected,
                onSelected: (_) => onValue(int.tryParse(e.key) ?? e.key),
              );
            }).toList(),
      );
    }

    if (field.input == MagicFieldInput.select) {
      final map = field.id == 'language' ? languages : field.values ?? {};
      if (map.isEmpty) {
        return _textInput(context, value, slot, onValue, isNumber: false);
      }
      final currentKey = value?.toString();
      final validKey = map.containsKey(currentKey) ? currentKey : null;
      return DropdownButtonFormField<String>(
        initialValue: validKey,
        isExpanded: true,
        decoration: const InputDecoration(
          isDense: true,
          border: OutlineInputBorder(),
        ),
        items:
            map.entries
                .map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                )
                .toList(),
        onChanged: (v) {
          if (v == null) return;
          onValue(field.id == 'rating' ? (int.tryParse(v) ?? v) : v);
        },
      );
    }

    if (field.type == MagicFieldType.date) {
      final text = value?.toString() ?? '';
      return InkWell(
        onTap: () async {
          final now = DateTime.now();
          final initial = DateTime.tryParse(text) ?? now;
          final picked = await showDatePicker(
            context: context,
            initialDate: initial,
            firstDate: DateTime(1900),
            lastDate: DateTime(now.year + 10),
          );
          if (picked != null) {
            final m = picked.month.toString().padLeft(2, '0');
            final d = picked.day.toString().padLeft(2, '0');
            onValue('${picked.year}-$m-$d');
          }
        },
        child: InputDecorator(
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.calendar_today_rounded, size: 18),
          ),
          child: Text(text.isEmpty ? 'YYYY-MM-DD' : text),
        ),
      );
    }

    final vocabType = _vocabTypeForField(field.id);
    if (vocabType != null) {
      return _VocabAutocompleteField(
        key: ValueKey('vocab-${identityHashCode(rule)}-${field.id}-$slot'),
        type: vocabType,
        initialValue: value?.toString() ?? '',
        onChanged: onValue,
      );
    }

    final isNumber =
        field.type == MagicFieldType.integer ||
        field.type == MagicFieldType.doubleType;
    return _textInput(context, value, slot, onValue, isNumber: isNumber);
  }

  static VocabularyType? _vocabTypeForField(String id) {
    switch (id) {
      case 'author':
        return VocabularyType.authors;
      case 'tag':
        return VocabularyType.tags;
      case 'series':
        return VocabularyType.series;
      case 'publisher':
        return VocabularyType.publishers;
      default:
        return null;
    }
  }

  Widget _textInput(
    BuildContext context,
    dynamic value,
    String slot,
    ValueChanged<dynamic> onValue, {
    required bool isNumber,
  }) {
    return TextFormField(
      key: ValueKey('txt-${identityHashCode(rule)}-${field.id}-$slot'),
      initialValue: value?.toString() ?? '',
      keyboardType:
          isNumber
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
      inputFormatters:
          isNumber
              ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]'))]
              : null,
      decoration: InputDecoration(
        isDense: true,
        border: const OutlineInputBorder(),
        labelText: AppLocalizations.of(context)!.value,
      ),
      onChanged: (text) {
        if (!isNumber) {
          onValue(text);
        } else if (field.type == MagicFieldType.integer) {
          onValue(int.tryParse(text));
        } else {
          onValue(double.tryParse(text));
        }
      },
    );
  }
}

class _VocabAutocompleteField extends StatefulWidget {
  final VocabularyType type;
  final String initialValue;
  final ValueChanged<dynamic> onChanged;

  const _VocabAutocompleteField({
    super.key,
    required this.type,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<_VocabAutocompleteField> createState() =>
      _VocabAutocompleteFieldState();
}

class _VocabAutocompleteFieldState extends State<_VocabAutocompleteField> {
  late final VocabularyRemoteDataSource _vocab = VocabularyRemoteDataSource(
    apiService: getIt<ApiService>(),
  );
  String _pending = '';

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: widget.initialValue),
      optionsBuilder: (textEditingValue) async {
        final q = textEditingValue.text.trim();
        if (q.length < 2) return const Iterable<String>.empty();
        _pending = q;
        await Future.delayed(const Duration(milliseconds: 250));
        if (!mounted || _pending != q) return const Iterable<String>.empty();
        final results = await _vocab.suggest(widget.type, q);
        return results.take(8);
      },
      onSelected: widget.onChanged,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            isDense: true,
            border: const OutlineInputBorder(),
            labelText: AppLocalizations.of(context)!.value,
            suffixIcon: const Icon(Icons.manage_search_rounded, size: 18),
          ),
          onChanged: widget.onChanged,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240, maxWidth: 360),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    title: Text(
                      option,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
