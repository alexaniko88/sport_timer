typedef SuccessHandler<T, R> = R Function(T value);
typedef FailureHandler<R> = R Function(Exception error);

sealed class Result<T> {
  const Result();

  R fold<R>({
    required SuccessHandler<T, R> onSuccess,
    required FailureHandler<R> onFailure,
  });
}

final class Success<T> extends Result<T> {
  final T value;

  const Success(this.value);

  @override
  R fold<R>({
    required SuccessHandler<T, R> onSuccess,
    required FailureHandler<R> onFailure,
  }) {
    return onSuccess(value);
  }
}

final class Failure<T> extends Result<T> {
  final Exception error;

  const Failure(this.error);

  @override
  R fold<R>({
    required SuccessHandler<T, R> onSuccess,
    required FailureHandler<R> onFailure,
  }) {
    return onFailure(error);
  }
}
