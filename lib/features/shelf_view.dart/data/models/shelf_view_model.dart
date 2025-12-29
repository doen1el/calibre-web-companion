import 'package:equatable/equatable.dart';

class ShelfViewModel extends Equatable {
  final String title;
  final String id;
  final bool isPublic;

  const ShelfViewModel({
    required this.title,
    required this.id,
    this.isPublic = false,
  });

  factory ShelfViewModel.fromJson(Map<String, dynamic> json) {
    return ShelfViewModel(
      title: json['title'],
      id: json['id'].split('/').last,
      isPublic: json['title'].toString().contains('(Public)'),
    );
  }

  ShelfViewModel copyWith({String? title, String? id, bool? isPublic}) {
    return ShelfViewModel(
      title: title ?? this.title,
      id: id ?? this.id,
      isPublic: isPublic ?? this.isPublic,
    );
  }

  @override
  List<Object?> get props => [title, id, isPublic];
}
