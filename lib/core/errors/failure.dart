abstract class Failure {
  final String errorMessage;
  const Failure({required this.errorMessage});

  @override
  String toString() => '$runtimeType(errorMessage: $errorMessage)';

  @override
  int get hashCode => Object.hash(runtimeType, errorMessage);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other.runtimeType == runtimeType &&
          other is Failure &&
          other.errorMessage == errorMessage;
}

class ServerFailure extends Failure {
  ServerFailure({required String errorMessage})
      : super(errorMessage: errorMessage);
}

class CacheFailure extends Failure {
  CacheFailure({required String errorMessage})
      : super(errorMessage: errorMessage);
}
