import 'package:equatable/equatable.dart';

class BookAuthor extends Equatable {
  final String name;
  final String id;

  const BookAuthor({required this.name, required this.id});

  @override
  List<Object?> get props => [name, id];
}
