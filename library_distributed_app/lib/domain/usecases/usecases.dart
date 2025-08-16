import 'dart:async';

import 'package:result_dart/result_dart.dart';

abstract class UseCase<ReturnType extends Object> {
  const UseCase();

  FutureOr<Result<ReturnType>> call();
}

abstract class VoidUseCase extends UseCase<String> {
  const VoidUseCase();

  Success<String, Exception> get success => const Success('OK');
  Failure<String, Exception> failure(dynamic e) =>
      Failure(e is Exception ? e : Exception(e.toString()));

  /// return [success] if the operation is successful, otherwise return [failure].
  @override
  FutureOr<Result<String>> call();
}

abstract class UseCaseWithParams<ResultType extends Object, Params> {
  const UseCaseWithParams();

  FutureOr<Result<ResultType>> call(Params params);
}

abstract class VoidUseCaseWithParams<Params>
    extends UseCaseWithParams<String, Params> {
  const VoidUseCaseWithParams();

  Success<String, Exception> get success => const Success('OK');
  Failure<String, Exception> failure(dynamic e) =>
      Failure(e is Exception ? e : Exception(e.toString()));

  /// return [success] if the operation is successful, otherwise return [failure].
  @override
  FutureOr<Result<String>> call(Params params);
}
