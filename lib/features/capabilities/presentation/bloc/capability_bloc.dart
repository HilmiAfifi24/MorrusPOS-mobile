import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/capability_repository.dart';
import 'capability_event.dart';
import 'capability_state.dart';

export 'capability_event.dart';
export 'capability_state.dart';

class CapabilityBloc extends Bloc<CapabilityEvent, CapabilityState> {
  final CapabilityRepository repository;
  String? _outletId;

  CapabilityBloc({required this.repository})
    : super(const CapabilityInitial()) {
    on<LoadCapabilities>((event, emit) => _load(event.outletId, emit));
    on<CapabilitiesStale>((event, emit) async {
      if (_outletId != null) await _load(_outletId!, emit);
    });
    on<ClearCapabilities>((event, emit) {
      _outletId = null;
      emit(const CapabilityInitial());
    });
  }

  Future<void> _load(String outletId, Emitter<CapabilityState> emit) async {
    _outletId = outletId;
    emit(const CapabilityLoading());
    try {
      emit(CapabilityLoaded(await repository.getEffective(outletId)));
    } catch (error) {
      emit(CapabilityFailure(error.toString()));
    }
  }
}
