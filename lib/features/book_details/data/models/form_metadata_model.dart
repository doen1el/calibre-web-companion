import 'package:equatable/equatable.dart';
import 'package:logger/logger.dart';

class FormatMetadataModel extends Equatable {
  final String format;
  final int? size;
  final String? mtime;
  final String? path;

  const FormatMetadataModel({
    required this.format,
    this.size,
    this.mtime,
    this.path,
  });

  factory FormatMetadataModel.fromJson(
    String format,
    Map<String, dynamic> json,
  ) {
    return FormatMetadataModel(
      format: format.toLowerCase(),
      size: int.tryParse(json['size']),
      mtime: json['mtime'],
      path: json['path'],
    );
  }

  @override
  List<Object?> get props => [format, size, mtime, path];
}

class FormatMetadata extends Equatable {
  final Map<String, FormatMetadataModel> formats;

  static final Logger _logger = Logger();

  const FormatMetadata({required this.formats});

  /// Parse the entire format_metadata structure from a JSON response
  factory FormatMetadata.fromJson(Map<String, dynamic> json) {
    final Map<String, FormatMetadataModel> formats = {};

    try {
      final formatMetadataJson = json['format_metadata'] as Map;

      formatMetadataJson.forEach((format, metadata) {
        if (metadata is Map<String, dynamic>) {
          formats[format.toLowerCase()] = FormatMetadataModel.fromJson(
            format,
            metadata,
          );
        }
      });
    } catch (e) {
      _logger.e('Error parsing format metadata: $e');
    }

    return FormatMetadata(formats: formats);
  }

  @override
  List<Object?> get props => [formats];
}
