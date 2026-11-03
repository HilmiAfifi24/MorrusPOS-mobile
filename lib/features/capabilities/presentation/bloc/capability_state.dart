import 'package:equatable/equatable.dart';
import '../../domain/entities/capability_snapshot_entity.dart';

sealed class CapabilityState extends Equatable {
  const CapabilityState();

  @override
  List<Object?> get props => [];
}

class CapabilityInitial extends CapabilityState {
  const CapabilityInitial();
}

class CapabilityLoading extends CapabilityState {
  const CapabilityLoading();
}

class CapabilityLoaded extends CapabilityState {
  final CapabilitySnapshotEntity snapshot;

  const CapabilityLoaded(this.snapshot);

  bool has(String code) => snapshot.has(code);

  @override
  List<Object?> get props => [snapshot];
}

class CapabilityFailure extends CapabilityState {
  final String message;

  const CapabilityFailure(this.message);

  @override
  List<Object?> get props => [message];
}
