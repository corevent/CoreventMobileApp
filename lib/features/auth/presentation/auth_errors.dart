import 'package:dio/dio.dart';

String authErrorMessage(
  Object error, {
  String fallback = 'Não foi possível concluir. Tente novamente.',
}) {
  if (error is DioException) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Sem conexão. Verifique sua internet e tente novamente.';
    }
    final status = error.response?.statusCode;
    if (status == 429) {
      return 'Muitas tentativas. Aguarde um momento e tente novamente.';
    }
    if (status != null && status >= 500) {
      return 'Serviço indisponível. Tente novamente mais tarde.';
    }
  }
  return fallback;
}
