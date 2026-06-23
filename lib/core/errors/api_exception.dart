class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  const ApiException({
    required this.message,
    this.statusCode,
    this.errors,
  });

  factory ApiException.fromResponse(Map<String, dynamic> json, int statusCode) {
    return ApiException(
      message: json['message'] as String? ?? 'An error occurred',
      statusCode: statusCode,
      errors: json['errors'] as Map<String, dynamic>?,
    );
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
