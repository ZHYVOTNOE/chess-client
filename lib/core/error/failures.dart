abstract class Failure {
  final String message;
  final int? statusCode;

  Failure(this.message, {this.statusCode});
}

class ServerFailure extends Failure {
  ServerFailure([String message = 'Server error occurred', int? statusCode])
      : super(message, statusCode: statusCode);
}

class CacheFailure extends Failure {
  CacheFailure([String message = 'Cache error occurred'])
      : super(message);
}

class NetworkFailure extends Failure {
  NetworkFailure([String message = 'Network error occurred'])
      : super(message);
}

class UnauthorizedFailure extends Failure {
  UnauthorizedFailure([String message = 'Unauthorized access'])
      : super(message, statusCode: 401);
}

class NotFoundFailure extends Failure {
  NotFoundFailure([String message = 'Resource not found'])
      : super(message, statusCode: 404);
}

class ValidationFailure extends Failure {
  ValidationFailure([String message = 'Validation error occurred'])
      : super(message);
}
