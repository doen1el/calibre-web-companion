import 'package:calibre_web_companion/features/login_settings/data/models/custom_header.dart';
import 'package:equatable/equatable.dart';

class LoginSettingsState extends Equatable {
  final List<CustomHeaderModel> customHeaders;
  final String basePath;
  final String reachabilityProbe;
  final bool isLoading;
  final bool isSaved;
  final bool allowSelfSigned;
  final String? errorMessage;
  final int formVersion;

  const LoginSettingsState({
    this.customHeaders = const [],
    this.basePath = '',
    this.reachabilityProbe = '',
    this.isLoading = false,
    this.isSaved = false,
    this.allowSelfSigned = false,
    this.errorMessage,
    this.formVersion = 0,
  });

  LoginSettingsState copyWith({
    List<CustomHeaderModel>? customHeaders,
    String? basePath,
    String? reachabilityProbe,
    bool? isLoading,
    bool? isSaved,
    bool? allowSelfSigned,
    String? errorMessage,
    int? formVersion,
  }) {
    return LoginSettingsState(
      customHeaders: customHeaders ?? this.customHeaders,
      basePath: basePath ?? this.basePath,
      reachabilityProbe: reachabilityProbe ?? this.reachabilityProbe,
      isLoading: isLoading ?? this.isLoading,
      isSaved: isSaved ?? this.isSaved,
      allowSelfSigned: allowSelfSigned ?? this.allowSelfSigned,
      errorMessage: errorMessage,
      formVersion: formVersion ?? this.formVersion,
    );
  }

  @override
  List<Object?> get props => [
    customHeaders,
    basePath,
    reachabilityProbe,
    isLoading,
    isSaved,
    allowSelfSigned,
    errorMessage,
    formVersion,
  ];
}
