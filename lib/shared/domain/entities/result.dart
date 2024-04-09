part of '../../shared.dart';

sealed class Result<S, F> {
  const Result();

  factory Result.success(S s) => Success(s);

  factory Result.failure(F f) => Failure(f);

  T fold<T>(T Function(S) success, T Function(F) failure) => switch (this) {
        Success(:final value) => success(value),
        Failure(:final value) => failure(value),
      };

  bool isSuccess() => switch (this) {
        Success() => true,
        Failure() => false,
      };

  bool isFailure() => !isSuccess();
}

class Success<S, F> extends Result<S, F> {
  const Success(this._s);

  final S _s;

  S get value => _s;
}

class Failure<S, F> extends Result<S, F> {
  const Failure(this._f);

  final F _f;

  F get value => _f;
}
