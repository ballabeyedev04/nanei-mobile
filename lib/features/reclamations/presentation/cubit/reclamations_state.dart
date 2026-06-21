import 'package:equatable/equatable.dart';
import '../../domain/entities/reclamation_entity.dart';

abstract class ReclamationsState extends Equatable {
  const ReclamationsState();
  @override
  List<Object?> get props => [];
}

class ReclamationsInitial extends ReclamationsState {
  const ReclamationsInitial();
}

class ReclamationsLoading extends ReclamationsState {
  const ReclamationsLoading();
}

class ReclamationsLoaded extends ReclamationsState {
  final List<ReclamationEntity> reclamations;
  const ReclamationsLoaded(this.reclamations);
  @override
  List<Object?> get props => [reclamations];
}

class ReclamationsError extends ReclamationsState {
  final String message;
  const ReclamationsError(this.message);
  @override
  List<Object?> get props => [message];
}

class ReclamationEnvoyee extends ReclamationsState {
  const ReclamationEnvoyee();
}

class ReclamationEnvoi extends ReclamationsState {
  const ReclamationEnvoi();
}
