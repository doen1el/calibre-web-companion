import 'package:equatable/equatable.dart';

class CustomColumnModel extends Equatable {
  // Template field, e.g. `#my_library`.
  final String key;
  final String name;
  final String value;
  // Set for yes/no columns, which calibre-web renders as an icon without text.
  final bool? boolValue;

  const CustomColumnModel({
    required this.key,
    required this.name,
    this.value = '',
    this.boolValue,
  });

  @override
  List<Object?> get props => [key, name, value, boolValue];
}
