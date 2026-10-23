sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  final T value;

  const Success(this.value);
}

final class Failure<T> extends Result<T> {
  final Exception error;

  const Failure(this.error);
}
