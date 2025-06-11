import 'package:equatable/equatable.dart';

class CategoryModel extends Equatable {
  final String id;
  final String title;

  const CategoryModel({required this.id, required this.title});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(id: json['id'] ?? '', title: json['title'] ?? '');
  }

  @override
  List<Object?> get props => [id, title];
}
