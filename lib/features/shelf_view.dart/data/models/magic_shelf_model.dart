import 'package:equatable/equatable.dart';

class MagicShelfModel extends Equatable {
  final String id;
  final String name;
  final String? icon;
  final bool isPublic;

  const MagicShelfModel({
    required this.id,
    required this.name,
    this.icon,
    this.isPublic = false,
  });

  factory MagicShelfModel.fromJson(Map<String, dynamic> json) {
    String id = json['id']?.toString() ?? '';

    id = id.split('/').last.split('?').last.replaceFirst('shelf_id=', '');

    var title = (json['title']?.toString() ?? '').trim();
    final isPublic = title.contains('(Public)');
    if (isPublic) {
      title = title.replaceAll('(Public)', '').trim();
    }

    title = title.replaceAll('(Magic)', '').trim();

    final icon = _leadingEmoji(title);
    String name = title;
    if (icon != null) {
      name = title.substring(icon.length).trim();
    }

    return MagicShelfModel(
      id: id,
      name: name.isEmpty ? title : name,
      icon: icon,
      isPublic: isPublic,
    );
  }

  static String? _leadingEmoji(String s) {
    final runes = s.runes.toList();
    if (runes.isEmpty || runes.first <= 0x2000) return null;

    bool isEmojiPart(int r) =>
        r > 0x2000 ||
        r == 0x200D ||
        (r >= 0xFE00 && r <= 0xFE0F) ||
        (r >= 0x1F3FB && r <= 0x1F3FF);

    int i = 0;
    while (i < runes.length && isEmojiPart(runes[i])) {
      i++;
    }
    if (i == 0) return null;
    return String.fromCharCodes(runes.sublist(0, i));
  }

  @override
  List<Object?> get props => [id, name, icon, isPublic];
}

class MagicShelfListModel extends Equatable {
  final List<MagicShelfModel> shelves;

  const MagicShelfListModel({required this.shelves});

  factory MagicShelfListModel.fromFeedJson(Map<String, dynamic> json) {
    final List<MagicShelfModel> shelves = [];
    try {
      final feed = json['feed'];
      if (feed == null) return const MagicShelfListModel(shelves: []);

      final entryRaw = feed['entry'];
      if (entryRaw is List) {
        for (final entry in entryRaw) {
          if (entry is Map) {
            shelves.add(
              MagicShelfModel.fromJson(Map<String, dynamic>.from(entry)),
            );
          }
        }
      } else if (entryRaw is Map) {
        shelves.add(
          MagicShelfModel.fromJson(Map<String, dynamic>.from(entryRaw)),
        );
      }
      return MagicShelfListModel(shelves: shelves);
    } catch (_) {
      return const MagicShelfListModel(shelves: []);
    }
  }

  @override
  List<Object?> get props => [shelves];
}
