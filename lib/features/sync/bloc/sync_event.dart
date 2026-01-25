import 'package:equatable/equatable.dart';
import 'package:calibre_web_companion/features/sync/data/models/sync_filter.dart';

abstract class SyncEvent extends Equatable {
  const SyncEvent();

  @override
  List<Object?> get props => [];
}

class CheckForUnsyncedBooks extends SyncEvent {
  final SyncFilter? filter;
  const CheckForUnsyncedBooks({this.filter});
}

class StartSync extends SyncEvent {
  final SyncFilter filter;
  final bool dryRun;

  const StartSync(this.filter, {this.dryRun = false});

  @override
  List<Object?> get props => [filter, dryRun];
}

class ConfirmSyncFromPreview extends SyncEvent {}

class PauseSync extends SyncEvent {}

class ResumeSync extends SyncEvent {}

class CancelSync extends SyncEvent {}

class ProcessNextSyncItem extends SyncEvent {}
