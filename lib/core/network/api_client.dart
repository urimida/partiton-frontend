import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:partition_app/core/config/app_config.dart';
import 'package:partition_app/core/platform/platform_config.dart';
import 'package:partition_app/core/storage/storage_service.dart';

class ApiClient {
  late final Dio _dio;
  final Logger _logger = Logger();

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: PlatformConfig.baseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // 인증이 필요 없는 엔드포인트 목록
          final publicEndpoints = [
            AppConfig.loginEndpoint,
            AppConfig.registerEndpoint,
            AppConfig.kakaoLoginEndpoint,
          ];
          
          // 공개 엔드포인트가 아닌 경우에만 토큰 추가
          final isPublicEndpoint = publicEndpoints.any(
            (endpoint) => options.path.contains(endpoint),
          );
          
          if (!isPublicEndpoint) {
            final token = await StorageService.getToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          
          _logger.d('Request: ${options.method} ${options.path}');
          _logger.d('Request Data: ${options.data}');
          _logger.d('Request Headers: ${options.headers}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.d('Response: ${response.statusCode} ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (error, handler) {
          _logger.e('Error: ${error.response?.statusCode} ${error.requestOptions.path}');
          if (error is DioException) {
            if (error.type == DioExceptionType.connectionTimeout ||
                error.type == DioExceptionType.receiveTimeout ||
                error.type == DioExceptionType.sendTimeout) {
              _logger.e('Timeout Error Details:');
              _logger.e('  - Type: ${error.type}');
              _logger.e('  - Message: ${error.message}');
              _logger.e('  - Request Path: ${error.requestOptions.path}');
              _logger.e('  - Base URL: ${error.requestOptions.baseUrl}');
            }
          }
          if (error.response != null) {
            _logger.e('Error Response Data: ${error.response?.data}');
            _logger.e('Error Response Headers: ${error.response?.headers}');
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      _logger.e('GET Error: $e');
      rethrow;
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      _logger.e('POST Error: $e');
      rethrow;
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      _logger.e('PUT Error: $e');
      rethrow;
    }
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      _logger.e('PATCH Error: $e');
      rethrow;
    }
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      _logger.e('DELETE Error: $e');
      rethrow;
    }
  }
}

