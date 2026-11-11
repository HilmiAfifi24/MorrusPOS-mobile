import 'package:equatable/equatable.dart';

sealed class CapabilityEvent extends Equatable {
  const CapabilityEvent();

  @override
  List<Object?> get props => [];
}

class LoadCapabilities extends CapabilityEvent {
  final String? outletId;

  const LoadCapabilities(this.outletId);

  @override
  List<Object?> get props => [outletId];
}

class CapabilitiesStale extends CapabilityEvent {
  const CapabilitiesStale();
}

class ClearCapabilities extends CapabilityEvent {
  const ClearCapabilities();
}
