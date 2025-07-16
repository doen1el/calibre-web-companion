import 'package:equatable/equatable.dart';

import 'package:calibre_web_companion/features/login_settings/data/models/custom_header.dart';

class LoginSettingsState extends Equatable {
  final List<CustomHeaderModel> customHeaders;
  final String basePath;
  final bool isLoading;
  final bool isSaved;
  final String? errorMessage;

  const LoginSettingsState({
    this.customHeaders = const [],
    this.basePath = '',
    this.isLoading = false,
    this.isSaved = false,
    this.errorMessage,
  });

  LoginSettingsState copyWith({
    List<CustomHeaderModel>? customHeaders,
    String? basePath,
    bool? isLoading,
    bool? isSaved,
    String? errorMessage,
  }) {
    return LoginSettingsState(
      customHeaders: customHeaders ?? this.customHeaders,
      basePath: basePath ?? this.basePath,
      isLoading: isLoading ?? this.isLoading,
      isSaved: isSaved ?? this.isSaved,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    customHeaders,
    basePath,
    isLoading,
    isSaved,
    errorMessage,
  ];
}
