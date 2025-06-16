import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

class ApiService {
  static const String baseUrl = 'https://api.donatellolab.com/';
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService() : _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
    contentType: 'application/json',
  )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Handle token refresh for 401 errors, but avoid refresh token endpoint
        if (error.response?.statusCode == 401 && 
            !error.requestOptions.path.contains('/api/auth/token/refresh/')) {
          try {
            final refreshResult = await refreshToken();

            // Retry the original request with new token
            final newToken = await _storage.read(key: 'jwt_token');
            if (newToken != null) {
              error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
              final retryResponse = await _dio.request(
                error.requestOptions.path,
                options: Options(
                  method: error.requestOptions.method,
                  headers: error.requestOptions.headers,
                ),
                data: error.requestOptions.data,
                queryParameters: error.requestOptions.queryParameters,
              );
              return handler.resolve(retryResponse);
            }
          } catch (refreshError) {
            // Clear tokens if refresh fails
            await _storage.delete(key: 'jwt_token');
            await _storage.delete(key: 'jwt_refresh_token');
            // Don't retry, let the error propagate
          }
        }
        handler.next(error);
      },
    ));
  }

  // Auth endpoints
  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/auth/register/', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post('/api/auth/token/', data: {
      'email': email,
      'password': password,
    });

    if (response.data['access'] != null) {
      await _storage.write(key: 'jwt_token', value: response.data['access']);
      await _storage.write(key: 'jwt_refresh_token', value: response.data['refresh']);
    }

    return response.data;
  }

  Future<Map<String, dynamic>> refreshToken() async {
    final refreshToken = await _storage.read(key: 'jwt_refresh_token');

    if (refreshToken == null) {
      throw Exception('No refresh token available');
    }

    try {
      final response = await _dio.post('/api/auth/token/refresh/', data: {
        'refresh': refreshToken,
      });

      if (response.data['access'] != null) {
        await _storage.write(key: 'jwt_token', value: response.data['access']);
        // Update refresh token if provided
        if (response.data['refresh'] != null) {
          await _storage.write(key: 'jwt_refresh_token', value: response.data['refresh']);
        }
      }

      return response.data;
    } catch (e) {
      // If refresh fails, clear all tokens
      await _storage.delete(key: 'jwt_token');
      await _storage.delete(key: 'jwt_refresh_token');
      throw e;
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _dio.get('/api/auth/user/me/');
    return response.data;
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await _dio.patch('/api/auth/user/update/', data: data);
    return response.data;
  }

  // Recipients endpoints
  Future<List<dynamic>> getRecipients() async {
    try {
      final response = await _dio.get('/api/recipients/');

      // Handle paginated response
      if (response.data is Map && response.data.containsKey('results')) {
        return response.data['results'] as List<dynamic>;
      }

      // Handle direct list response (fallback)
      if (response.data is List) {
        return response.data as List<dynamic>;
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> createRecipient(Map<String, dynamic> recipientData) async {
    try {
      final response = await _dio.post('/api/recipients/', data: recipientData);
      return response.data;
    } catch (e) {
      throw Exception('Errore nella creazione del destinatario');
    }
  }

  Future<Map<String, dynamic>> getRecipient(int id) async {
    final response = await _dio.get('/api/recipients/$id/');
    return response.data;
  }

  Future<Map<String, dynamic>> updateRecipient(int id, Map<String, dynamic> data) async {
    final response = await _dio.patch('/api/recipients/$id/', data: data);
    return response.data;
  }

  Future<void> deleteRecipient(int id) async {
    await _dio.delete('/api/recipients/$id/');
  }

  // Gift generation endpoints
  Future<Map<String, dynamic>?> generateGiftIdeas(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/api/generate-gift-ideas/', data: data);

      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }

      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 500) {
        throw Exception('Server error. Please try again later.');
      } else if (e.response?.statusCode == 400) {
        throw Exception('Invalid request data.');
      } else if (e.type == DioExceptionType.connectionTimeout || 
                 e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Connection timeout. Check your internet connection.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Connection error. Check your internet connection.');
      }

      throw Exception('Network error occurred.');
    } catch (e) {
      throw Exception('Unexpected error occurred.');
    }
  }

  Future<Map<String, dynamic>> generateGiftIdeasForRecipient(int recipientId, Map<String, dynamic> data) async {
    final response = await _dio.post('/api/generate-gift-ideas/recipient/$recipientId/', data: data);
    return response.data;
  }

  // Saved gifts endpoints
  Future<List<dynamic>> getSavedGifts() async {
    try {
      final response = await _dio.get('/api/saved-gifts/');

      // Handle paginated response structure
      if (response.data is Map && response.data.containsKey('results')) {
        return response.data['results'] as List<dynamic>;
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> saveGift(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/saved-gifts/', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> getSavedGift(int id) async {
    final response = await _dio.get('/api/saved-gifts/$id/');
    return response.data;
  }

  Future<Map<String, dynamic>> updateSavedGift(int id, Map<String, dynamic> data) async {
    final response = await _dio.patch('/api/saved-gifts/$id/', data: data);
    return response.data;
  }

  Future<void> deleteSavedGift(int id) async {
    await _dio.delete('/api/saved-gifts/$id/');
  }

  // Popular gifts endpoints
  Future<List<dynamic>> getPopularGifts() async {
    try {
      final response = await _dio.get('/api/popular-gifts/');

      // Handle paginated response
      if (response.data is Map && response.data.containsKey('results')) {
        return response.data['results'] as List<dynamic>;
      }

      // Handle direct list response (fallback)
      if (response.data is List) {
        return response.data as List<dynamic>;
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  // History endpoints
  Future<List<dynamic>> getHistory() async {
    final response = await _dio.get('/api/history/');
    return response.data;
  }

  Future<Map<String, dynamic>> getHistoryDetail(int id) async {
    final response = await _dio.get('/api/history/$id/');
    return response.data;
  }

  Future<void> requestPasswordReset(String email) async {
    await _dio.post('/api/auth/password-reset/', data: {'email': email});
  }

  Future<void> validateResetToken(String token) async {
    await _dio.get('/api/auth/password-reset/validate/$token/');
  }

  Future<void> confirmPasswordReset(String token, String newPassword, String confirmPassword) async {
    await _dio.post('/api/auth/password-reset/confirm/', data: {
      'token': token,
      'new_password': newPassword,
      'confirm_password': confirmPassword,
    });
  }
}