import '../../domain/entities/capability_snapshot_entity.dart';

class CapabilitySnapshotModel extends CapabilitySnapshotEntity {
  const CapabilitySnapshotModel({
    required super.outletId,
    required super.revision,
    required super.enabledCodes,
  });

  factory CapabilitySnapshotModel.fromJson(Map<String, dynamic> json) {
    final capabilities = json['capabilities'];
    if (capabilities is! List) {
      throw const FormatException('Daftar capability tidak valid.');
    }

    final enabledCodes = capabilities
        .whereType<Map<String, dynamic>>()
        .where((item) => item['enabled'] == true && item['code'] is String)
        .map((item) => item['code'] as String)
        .toSet();

    return CapabilitySnapshotModel(
      outletId: json['outletId']?.toString(),
      revision: (json['revision'] as num?)?.toInt() ?? 0,
      enabledCodes: Set.unmodifiable(enabledCodes),
    );
  }
}
