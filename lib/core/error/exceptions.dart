abstract class AppException implements Exception {
  final String message;
  final int? statusCode;

  AppException(this.message, {this.statusCode});
}

class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'Server error']);

  @override
  String toString() => message;
}

class CacheException extends AppException {
  CacheException([String message = 'Cache error occurred'])
      : super(message);
}

class NetworkException extends AppException {
  NetworkException([String message = 'Network error occurred'])
      : super(message);
}

class UnauthorizedException extends AppException {
  UnauthorizedException([String message = 'Unauthorized access'])
      : super(message, statusCode: 401);
}

class NotFoundException extends AppException {
  NotFoundException([String message = 'Resource not found'])
      : super(message, statusCode: 404);
}
