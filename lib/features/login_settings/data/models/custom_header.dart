class CustomHeaderModel {
  final String key;
  final String value;

  CustomHeaderModel({required this.key, required this.value});

  factory CustomHeaderModel.fromMap(Map<String, dynamic> map) {
    return CustomHeaderModel(
      key: map['key'] as String,
      value: map['value'] as String,
    );
  }

  Map<String, String> toMap() => {'key': key, 'value': value};

  @override
  String toString() => 'CustomHeader(key: $key, value: $value)';

  static List<CustomHeaderModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map(
          (item) => CustomHeaderModel.fromMap(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  static List<Map<String, dynamic>> toJsonList(
    List<CustomHeaderModel?> headers,
  ) {
    return headers
        .where((header) => header != null)
        .map((header) => header!.toMap())
        .toList();
  }
}
