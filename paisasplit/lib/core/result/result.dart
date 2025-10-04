sealed class Result<T, E> {
  const Result();

  bool get isSuccess => this is Success<T, E>;
  bool get isFailure => this is Failure<T, E>;

  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(E error) onFailure,
  }) {
    final self = this;
    if (self is Success<T, E>) {
      return onSuccess(self.value);
    }
    final failure = self as Failure<T, E>;
    return onFailure(failure.error);
  }

  Result<U, E> map<U>(U Function(T value) transform) {
    final self = this;
    if (self is Success<T, E>) {
      return Success<U, E>(transform(self.value));
    }
    final failure = self as Failure<T, E>;
    return Failure<U, E>(failure.error);
  }

  Result<T, F> mapError<F>(F Function(E error) transform) {
    final self = this;
    if (self is Success<T, E>) {
      return Success<T, F>(self.value);
    }
    final failure = self as Failure<T, E>;
    return Failure<T, F>(transform(failure.error));
  }

  static Result<T, E> success<T, E>(T value) => Success<T, E>(value);
  static Result<T, E> failure<T, E>(E error) => Failure<T, E>(error);
}

final class Success<T, E> extends Result<T, E> {
  const Success(this.value);

  final T value;
}

final class Failure<T, E> extends Result<T, E> {
  const Failure(this.error);

  final E error;
}
