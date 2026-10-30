import 'package:dio/dio.dart';
import 'package:json_annotation/json_annotation.dart';

enum ErrorKind { connection, timeout, client, server, json, unknown }

class AppException implements Exception {
  final ErrorKind kind;
  final String message;
  const AppException(this.kind, this.message);
  static AppException from(Object error) {
    if (error is AppException) return error;
    if (error is DioException) {
      if ([
        DioExceptionType.connectionTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.sendTimeout,
      ].contains(error.type)) {
        return const AppException(
          ErrorKind.timeout,
          'Время ожидания истекло. Повторите запрос.',
        );
      }
      final status = error.response?.statusCode ?? 0;
      if (status >= 500) {
        return const AppException(
          ErrorKind.server,
          'Сервер временно недоступен. Повторите позже.',
        );
      }
      if (status >= 400) {
        return const AppException(
          ErrorKind.client,
          'Сервер отклонил запрос. Проверьте данные.',
        );
      }
      if (error.type == DioExceptionType.connectionError) {
        return const AppException(
          ErrorKind.connection,
          'Нет соединения. Проверьте интернет.',
        );
      }
      if (error.error != null) return from(error.error!);
    }
    if (error is CheckedFromJsonException ||
        error is FormatException ||
        error is TypeError) {
      return const AppException(
        ErrorKind.json,
        'Получен некорректный ответ сервера.',
      );
    }
    return const AppException(
      ErrorKind.unknown,
      'Не удалось выполнить операцию. Попробуйте ещё раз.',
    );
  }

  @override
  String toString() => message;
}
