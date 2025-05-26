
class AuthException implements Exception {
  final String message;
  final String? code;
  
  const AuthException(this.message, {this.code});
  
  @override
  String toString() => message;
}

class NetworkException extends AuthException {
  const NetworkException(super.message) : super(code: 'NETWORK_ERROR');
}

class ValidationException extends AuthException {
  const ValidationException(super.message) : super(code: 'VALIDATION_ERROR');
}

class UnauthorizedException extends AuthException {
  const UnauthorizedException(super.message) : super(code: 'UNAUTHORIZED');
}

class ServerException extends AuthException {
  const ServerException(super.message) : super(code: 'SERVER_ERROR');
}
