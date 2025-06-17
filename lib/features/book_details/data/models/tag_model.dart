import 'package:equatable/equatable.dart';

class TagModel extends Equatable {
  final int id;
  final String name;

  const TagModel({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
