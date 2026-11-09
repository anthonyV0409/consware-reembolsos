/// Error presentable al usuario. [isConnectionError] permite ofrecer "Reintentar".
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final bool isConnectionError;

  const ApiException(this.message, {this.statusCode, this.isConnectionError = false});

  @override
  String toString() => message;
}
