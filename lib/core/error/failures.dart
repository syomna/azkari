import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String? message;
  const Failure([this.message]);
  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message]);

  @override
  List<Object?> get props => [message];
}

class CacheFailure extends Failure {
  const CacheFailure([super.message]);

  @override
  List<Object?> get props => [message];
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message]);

  @override
  List<Object?> get props => [message];
}

class JsonParsingFailure extends Failure {
  const JsonParsingFailure([super.message]);

  @override
  List<Object?> get props => [message];
}
