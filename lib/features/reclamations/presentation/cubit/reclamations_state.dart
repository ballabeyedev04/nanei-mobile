import 'package:equatable/equatable.dart';
import 'package:nanei/core/utils/pagination.dart';
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
  final InfoPagination pagination;
  ReclamationsLoaded(this.reclamations, {InfoPagination? pagination})
      : pagination = pagination ?? InfoPagination.unePage(reclamations.length);
  @override
  List<Object?> get props => [reclamations, pagination];
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
