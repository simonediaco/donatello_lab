import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

class ApiService {
  static const String baseUrl = 'http://localhost:8000';
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService() : _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
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
    final response = await _dio.post('/api/auth/token/refresh/', data: {
      'refresh': refreshToken,
    });

    if (response.data['access'] != null) {
      await _storage.write(key: 'jwt_token', value: response.data['access']);
    }

    return response.data;
  }

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _dio.get('/api/auth/me/');
    return response.data;
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await _dio.patch('/api/users/update_profile/', data: data);
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
      print('Error getting recipients: $e');

      // Handle token expiration
      if (e is DioException && e.response?.statusCode == 401) {
        try {
          await refreshToken();
          // Retry the request after refreshing token
          final retryResponse = await _dio.get('/api/recipients/');
          if (retryResponse.data is Map && retryResponse.data.containsKey('results')) {
            return retryResponse.data['results'] as List<dynamic>;
          }
          if (retryResponse.data is List) {
            return retryResponse.data as List<dynamic>;
          }
        } catch (refreshError) {
          print('Token refresh failed: $refreshError');
          // Clear tokens if refresh fails
          await _storage.delete(key: 'jwt_token');
          await _storage.delete(key: 'jwt_refresh_token');
          throw Exception('Sessione scaduta. Effettua nuovamente il login.');
        }
      }

      return [];
    }
  }

  Future<Map<String, dynamic>> createRecipient(Map<String, dynamic> recipientData) async {
    try {
      final response = await _dio.post('/api/recipients/', data: recipientData);
      return response.data;
    } catch (e) {
      print('Error creating recipient: $e');
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
  Future<Map<String, dynamic>> generateGiftIdeas(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/generate-gift-ideas/', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> generateGiftIdeasForRecipient(int recipientId, Map<String, dynamic> data) async {
    final response = await _dio.post('/api/generate-gift-ideas/recipient/$recipientId/', data: data);
    return response.data;
  }

  // Saved gifts endpoints
  Future<List<dynamic>> getSavedGifts() async {
    final response = await _dio.get('/api/saved-gifts/');
    return response.data;
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

  // History endpoints
  Future<List<dynamic>> getHistory() async {
    final response = await _dio.get('/api/history/');
    return response.data;
  }

  Future<Map<String, dynamic>> getHistoryDetail(int id) async {
    final response = await _dio.get('/api/history/$id/');
    return response.data;
  }
}