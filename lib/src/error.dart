class ErrorResponse {
  String error;
  String errorCode;

  ErrorResponse({required this.error, required this.errorCode});

  factory ErrorResponse.fromError(dynamic err) {
    return ErrorResponse(
      error: err.error,
      errorCode: err.errorCode,
    );
  }
}
