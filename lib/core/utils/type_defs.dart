import 'package:dev_quotes/core/error/failures.dart';

/// Simple Result type using a sealed class or just a custom class.
/// For simplicity and without external functional libraries like dartz,
/// we can use a simple sealed class pattern or just return nullable.
/// However, the requirement says "return result types (Success, Failure)".

sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Error<T> extends Result<T> {
  final Failure failure;
  const Error(this.failure);
}
