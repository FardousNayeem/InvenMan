enum AppExceptionKind {
  validation,
  notFound,
  conflict,
  storage,
  backup,
  unknown,
}

class AppException implements Exception {
  final String code;
  final String message;
  final AppExceptionKind kind;

  const AppException({
    required this.code,
    required this.message,
    required this.kind,
  });

  const AppException.validation({
    required this.code,
    required this.message,
  }) : kind = AppExceptionKind.validation;

  const AppException.notFound({
    required this.code,
    required this.message,
  }) : kind = AppExceptionKind.notFound;

  const AppException.conflict({
    required this.code,
    required this.message,
  }) : kind = AppExceptionKind.conflict;

  const AppException.storage({
    required this.code,
    required this.message,
  }) : kind = AppExceptionKind.storage;

  const AppException.backup({
    required this.code,
    required this.message,
  }) : kind = AppExceptionKind.backup;

  const AppException.unknown({
    required this.code,
    required this.message,
  }) : kind = AppExceptionKind.unknown;

  @override
  String toString() => message;
}