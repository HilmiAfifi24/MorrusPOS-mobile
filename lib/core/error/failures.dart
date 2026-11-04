import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class TrackingFailure extends Failure {
  final String code;

  const TrackingFailure(this.code, super.message);

  @override
  List<Object> get props => [code, message];
}

class IdempotencyFailure extends Failure {
  final String code;

  const IdempotencyFailure(this.code, super.message);

  @override
  List<Object> get props => [code, message];
}

class CacheFailure extends Failure {
  const CacheFailure() : super('Gagal memuat data lokal.');
}

class NetworkFailure extends Failure {
  const NetworkFailure() : super('Koneksi internet bermasalah.');
}

class CapabilityDisabledFailure extends Failure {
  final String capabilityCode;

  const CapabilityDisabledFailure(this.capabilityCode, super.message);

  @override
  List<Object> get props => [capabilityCode, message];
}
