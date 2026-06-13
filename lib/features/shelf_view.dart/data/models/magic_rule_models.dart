library;

enum MagicFieldType { string, integer, doubleType, date }

enum MagicFieldInput { text, select, radio }

class MagicField {
  final String id;
  final String label;
  final MagicFieldType type;
  final MagicFieldInput input;
  final Map<String, String>? values;

  const MagicField({
    required this.id,
    required this.label,
    required this.type,
    this.input = MagicFieldInput.text,
    this.values,
  });

  String get typeString {
    switch (type) {
      case MagicFieldType.string:
        return 'string';
      case MagicFieldType.integer:
        return 'integer';
      case MagicFieldType.doubleType:
        return 'double';
      case MagicFieldType.date:
        return 'date';
    }
  }

  String get inputString {
    switch (input) {
      case MagicFieldInput.text:
        return 'text';
      case MagicFieldInput.select:
        return 'select';
      case MagicFieldInput.radio:
        return 'radio';
    }
  }

  MagicField copyWith({Map<String, String>? values}) => MagicField(
    id: id,
    label: label,
    type: type,
    input: input,
    values: values ?? this.values,
  );
}

const List<MagicField> kMagicFields = [
  MagicField(id: 'title', label: 'Title', type: MagicFieldType.string),
  MagicField(id: 'author', label: 'Author', type: MagicFieldType.string),
  MagicField(id: 'tag', label: 'Tag', type: MagicFieldType.string),
  MagicField(id: 'series', label: 'Series', type: MagicFieldType.string),
  MagicField(id: 'publisher', label: 'Publisher', type: MagicFieldType.string),
  MagicField(
    id: 'language',
    label: 'Language',
    type: MagicFieldType.string,
    input: MagicFieldInput.select,
  ),
  MagicField(
    id: 'rating',
    label: 'Rating',
    type: MagicFieldType.integer,
    input: MagicFieldInput.select,
    values: {
      '1': '1',
      '2': '2',
      '3': '3',
      '4': '4',
      '5': '5',
      '6': '6',
      '7': '7',
      '8': '8',
      '9': '9',
      '10': '10',
    },
  ),
  MagicField(id: 'pubdate', label: 'Published Date', type: MagicFieldType.date),
  MagicField(id: 'timestamp', label: 'Date Added', type: MagicFieldType.date),
  MagicField(
    id: 'has_cover',
    label: 'Has Cover',
    type: MagicFieldType.integer,
    input: MagicFieldInput.radio,
    values: {'1': 'Yes', '0': 'No'},
  ),
  MagicField(
    id: 'read_status',
    label: 'Read Status',
    type: MagicFieldType.integer,
    input: MagicFieldInput.radio,
    values: {'0': 'Unread', '1': 'Read'},
  ),
  MagicField(
    id: 'series_index',
    label: 'Series Index',
    type: MagicFieldType.doubleType,
  ),
  MagicField(id: 'comments', label: 'Description', type: MagicFieldType.string),
  MagicField(
    id: 'hardcover_id',
    label: 'Has Hardcover ID',
    type: MagicFieldType.integer,
    input: MagicFieldInput.radio,
    values: {'1': 'Yes', '0': 'No'},
  ),
];

MagicField magicFieldById(String id) => kMagicFields.firstWhere(
  (f) => f.id == id,
  orElse: () => kMagicFields.first,
);

class MagicOperator {
  final String id;
  final String label;
  final int valueCount;
  final bool isList;

  const MagicOperator(
    this.id,
    this.label, {
    this.valueCount = 1,
    this.isList = false,
  });
}

const List<MagicOperator> _allOperators = [
  MagicOperator('equal', 'equal'),
  MagicOperator('not_equal', 'not equal'),
  MagicOperator('in', 'in', isList: true),
  MagicOperator('not_in', 'not in', isList: true),
  MagicOperator('less', 'less'),
  MagicOperator('less_or_equal', 'less or equal'),
  MagicOperator('greater', 'greater'),
  MagicOperator('greater_or_equal', 'greater or equal'),
  MagicOperator('between', 'between', valueCount: 2),
  MagicOperator('not_between', 'not between', valueCount: 2),
  MagicOperator('begins_with', 'begins with'),
  MagicOperator('not_begins_with', "doesn't begin with"),
  MagicOperator('contains', 'contains'),
  MagicOperator('not_contains', "doesn't contain"),
  MagicOperator('ends_with', 'ends with'),
  MagicOperator('not_ends_with', "doesn't end with"),
  MagicOperator('is_empty', 'is empty', valueCount: 0),
  MagicOperator('is_not_empty', 'is not empty', valueCount: 0),
];

MagicOperator magicOperatorById(String id) => _allOperators.firstWhere(
  (o) => o.id == id,
  orElse: () => _allOperators.first,
);

List<MagicOperator> operatorsForField(MagicField field) {
  List<String> ids;
  if (field.input == MagicFieldInput.radio) {
    ids = ['equal', 'not_equal'];
  } else if (field.input == MagicFieldInput.select &&
      field.type == MagicFieldType.string) {
    ids = ['equal', 'not_equal', 'in', 'not_in'];
  } else {
    switch (field.type) {
      case MagicFieldType.string:
        ids = [
          'equal',
          'not_equal',
          'in',
          'not_in',
          'begins_with',
          'not_begins_with',
          'contains',
          'not_contains',
          'ends_with',
          'not_ends_with',
          'is_empty',
          'is_not_empty',
        ];
        break;
      case MagicFieldType.integer:
      case MagicFieldType.doubleType:
        ids = [
          'equal',
          'not_equal',
          'in',
          'not_in',
          'less',
          'less_or_equal',
          'greater',
          'greater_or_equal',
          'between',
          'not_between',
        ];
        break;
      case MagicFieldType.date:
        ids = [
          'equal',
          'not_equal',
          'less',
          'less_or_equal',
          'greater',
          'greater_or_equal',
          'between',
          'not_between',
        ];
        break;
    }
  }
  return ids.map(magicOperatorById).toList();
}

abstract class MagicNode {
  Map<String, dynamic> toJson();
}

class MagicRule extends MagicNode {
  String fieldId;
  String operatorId;
  dynamic value;

  MagicRule({required this.fieldId, required this.operatorId, this.value});

  factory MagicRule.defaultRule() =>
      MagicRule(fieldId: 'title', operatorId: 'contains', value: '');

  @override
  Map<String, dynamic> toJson() {
    final field = magicFieldById(fieldId);
    return {
      'id': fieldId,
      'field': fieldId,
      'type': field.typeString,
      'input': field.inputString,
      'operator': operatorId,
      'value': value,
    };
  }

  static MagicRule fromJson(Map<String, dynamic> json) {
    return MagicRule(
      fieldId: (json['id'] ?? json['field'] ?? 'title').toString(),
      operatorId: (json['operator'] ?? 'contains').toString(),
      value: json['value'],
    );
  }
}

class MagicShelfFormData {
  final String name;
  final String icon;
  final bool koboSync;
  final bool isPublic;
  final bool isSystem;
  final bool canBePublic;
  final Map<String, String> languages;
  final MagicGroup? rules;

  const MagicShelfFormData({
    this.name = '',
    this.icon = '🪄',
    this.koboSync = false,
    this.isPublic = false,
    this.isSystem = false,
    this.canBePublic = false,
    this.languages = const {},
    this.rules,
  });
}

class MagicGroup extends MagicNode {
  String condition;
  List<MagicNode> children;

  MagicGroup({this.condition = 'AND', List<MagicNode>? children})
    : children = children ?? [];

  factory MagicGroup.empty() =>
      MagicGroup(condition: 'AND', children: [MagicRule.defaultRule()]);

  @override
  Map<String, dynamic> toJson() => {
    'condition': condition,
    'rules': children.map((c) => c.toJson()).toList(),
  };

  static MagicGroup fromJson(Map<String, dynamic> json) {
    final condition = (json['condition'] ?? 'AND').toString().toUpperCase();
    final rawRules = json['rules'];
    final children = <MagicNode>[];
    if (rawRules is List) {
      for (final r in rawRules) {
        if (r is Map) {
          final map = Map<String, dynamic>.from(r);
          if (map.containsKey('condition')) {
            children.add(MagicGroup.fromJson(map));
          } else {
            children.add(MagicRule.fromJson(map));
          }
        }
      }
    }
    return MagicGroup(condition: condition, children: children);
  }
}
