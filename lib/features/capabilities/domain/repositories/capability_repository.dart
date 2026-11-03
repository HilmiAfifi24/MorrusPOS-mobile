import '../entities/capability_snapshot_entity.dart';

abstract class CapabilityRepository {
  Future<CapabilitySnapshotEntity> getEffective(String outletId);
}
