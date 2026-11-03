import 'package:equatable/equatable.dart';

class CapabilitySnapshotEntity extends Equatable {
  final String? outletId;
  final int revision;
  final Set<String> enabledCodes;

  const CapabilitySnapshotEntity({
    required this.outletId,
    required this.revision,
    required this.enabledCodes,
  });

  bool has(String code) => enabledCodes.contains(code);

  @override
  List<Object?> get props => [
    outletId,
    revision,
    ...enabledCodes.toList()..sort(),
  ];
}
