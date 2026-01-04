import 'package:equatable/equatable.dart';

import 'package:calibre_web_companion/features/me/data/models/stats_model.dart';

enum MeStatus { initial, loading, loaded, error }

enum LogoutStatus { initial, loading, success, error }

class MeState extends Equatable {
  final MeStatus status;
  final LogoutStatus logoutStatus;
  final StatsModel? stats;
  final String? errorMessage;
  final bool isOpds;

  const MeState({
    this.status = MeStatus.initial,
    this.logoutStatus = LogoutStatus.initial,
    this.stats,
    this.errorMessage,
    this.isOpds = false,
  });

  MeState copyWith({
    MeStatus? status,
    StatsModel? stats,
    String? errorMessage,
    LogoutStatus? logoutStatus,
    bool? isOpds,
  }) {
    return MeState(
      status: status ?? this.status,
      logoutStatus: logoutStatus ?? this.logoutStatus,
      stats: stats ?? this.stats,
      errorMessage: errorMessage,
      isOpds: isOpds ?? this.isOpds,
    );
  }

  @override
  List<Object?> get props => [status, logoutStatus, stats, errorMessage, isOpds];
}
