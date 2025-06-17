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

  Map<String, dynamic> toJson() {
    return {
      'format': format,
      'size': size?.toString(),
      'mtime': mtime,
      'path': path,
    };
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
    try {
      Map<String, FormatMetadataModel> formats = {};

      // Extract format metadata if available
      if (json.containsKey('format_metadata') &&
          json['format_metadata'] != null) {
        final formatData = json['format_metadata'] as Map<String, dynamic>;

        formatData.forEach((format, metadata) {
          if (metadata is Map) {
            // Convert metadata to FormatMetadataModel
            final formatModel = FormatMetadataModel.fromJson(
              format,
              Map<String, dynamic>.from(metadata),
            );
            formats[format] = formatModel;
          }
        });
      }

      return FormatMetadata(formats: formats);
    } catch (e) {
      print('Error parsing format metadata: $e');
      return FormatMetadata(formats: {});
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {'format_metadata': {}};

    formats.forEach((format, metadata) {
      json['format_metadata'][format] = metadata.toJson();
    });

    return json;
  }

  @override
  List<Object?> get props => [formats];
}
