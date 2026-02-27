import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/config/api_config.dart';
import 'log_service.dart';

class ApiService {
  late final Dio _dio;
  final LogService _logService = LogService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: Duration(milliseconds: ApiConfig.connectTimeout),
        receiveTimeout: Duration(milliseconds: ApiConfig.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _initializeInterceptors();
    _logService.cleanOldLogs(); // Clean old logs on startup
  }

  void _initializeInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'jwt_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          final message = 'REQUEST[${options.method}] => PATH: ${options.path} | DATA: ${options.data}';
          _log(message);
          return handler.next(options);
        },
        onResponse: (response, handler) {
          final message = 'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path} | DATA: ${response.data}';
          _log(message);
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          final message = 'ERROR[${e.response?.statusCode}] => PATH: ${e.requestOptions.path} | MESSAGE: ${e.message}';
          _log(message);
          return handler.next(e);
        },
      ),
    );
  }

  void _log(String message) {
    if (kDebugMode) {
      print(message);
      _logService.logToFile(message);
    }
  }

  // Generic GET method
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Generic POST method
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Global Error Handling
  Exception _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return Exception('Connection timed out. Please check your internet connection.');
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final dynamic data = error.response?.data;
          
          String? detailMessage;
          if (data is Map && data.containsKey('detail')) {
            detailMessage = data['detail'].toString();
          }

          if (statusCode == 500) {
            return Exception(detailMessage ?? 'Server error. Please try again later.');
          } else if (statusCode == 401) {
            return Exception(detailMessage ?? 'Unauthorized. Please login again.');
          } else if (statusCode == 400) {
            return Exception(detailMessage ?? 'Invalid request. Please check your input.');
          } else if (statusCode == 403) {
            return Exception(detailMessage ?? 'Access denied.');
          } else if (statusCode == 404) {
             return Exception(detailMessage ?? 'Resource not found.');
          }
          return Exception(detailMessage ?? 'An error occurred. Please try again.');
        case DioExceptionType.cancel:
          return Exception('Request to API was cancelled');
        case DioExceptionType.connectionError:
          return Exception('No internet connection. Please check if the server is running.');
        case DioExceptionType.unknown:
          if (error.message?.contains('SocketException') ?? false) {
             return Exception('Cannot reach the server. Please check your network.');
          }
          return Exception('An unknown error occurred: ${error.message ?? 'Unknown cause'}');
        default:
          return Exception('Unexpected error occurred: ${error.message ?? error.type.toString()}');
      }
    } else {
      return Exception('Local error: ${error.toString()}');
    }
  }
}
