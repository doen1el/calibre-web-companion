import 'package:equatable/equatable.dart';

abstract class LoginSettingsEvent extends Equatable {
  const LoginSettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadLoginSettings extends LoginSettingsEvent {
  const LoadLoginSettings();
}

class AddCustomHeader extends LoginSettingsEvent {
  const AddCustomHeader();
}

class DeleteCustomHeader extends LoginSettingsEvent {
  final int index;

  const DeleteCustomHeader(this.index);

  @override
  List<Object?> get props => [index];
}

class UpdateCustomHeaderKey extends LoginSettingsEvent {
  final int index;
  final String newKey;

  const UpdateCustomHeaderKey(this.index, this.newKey);

  @override
  List<Object?> get props => [index, newKey];
}

class UpdateCustomHeaderValue extends LoginSettingsEvent {
  final int index;
  final String newValue;

  const UpdateCustomHeaderValue(this.index, this.newValue);

  @override
  List<Object?> get props => [index, newValue];
}

class ApplyCloudflareAccessToken extends LoginSettingsEvent {
  final String clientId;
  final String clientSecret;

  const ApplyCloudflareAccessToken({
    required this.clientId,
    required this.clientSecret,
  });

  @override
  List<Object?> get props => [clientId, clientSecret];
}

class UpdateBasePath extends LoginSettingsEvent {
  final String basePath;

  const UpdateBasePath(this.basePath);

  @override
  List<Object?> get props => [basePath];
}

class UpdateReachabilityProbe extends LoginSettingsEvent {
  final String endpoint;

  const UpdateReachabilityProbe(this.endpoint);

  @override
  List<Object?> get props => [endpoint];
}

class UpdateAllowSelfSigned extends LoginSettingsEvent {
  final bool allowSelfSigned;

  const UpdateAllowSelfSigned(this.allowSelfSigned);

  @override
  List<Object?> get props => [allowSelfSigned];
}
