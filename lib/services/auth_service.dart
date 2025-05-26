import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../models/user.dart';
import '../models/auth_exception.dart';
import 'api_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.read(apiServiceProvider));
});

final currentUserProvider = StateProvider<User?>((ref) => null);

class AuthService {
  final ApiService _apiService;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthService(this._apiService);

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'jwt_token');
    return token != null;
  }

  Future<User?> login(String email, String password) async {
    try {
      await _apiService.login(email, password);
      final profileData = await _apiService.getProfile();
      return User.fromJson(profileData);
    } catch (e) {
      // Log dell'errore per debug
      print('AuthService login error: $e');
      
      // Rimuovi eventuali token corrotti
      await _storage.delete(key: 'jwt_token');
      
      // Gestione specifica per DioException
      if (e is DioException) {
        switch (e.response?.statusCode) {
          case 400:
          case 401:
            throw const UnauthorizedException('Email o password non corretti');
          case 404:
            throw const NetworkException('Servizio non disponibile');
          case 500:
            throw const ServerException('Errore del server. Riprova più tardi');
          default:
            if (e.type == DioExceptionType.connectionTimeout || 
                e.type == DioExceptionType.receiveTimeout ||
                e.type == DioExceptionType.connectionError) {
              throw const NetworkException('Problema di connessione. Controlla la tua rete');
            }
            throw NetworkException('Errore di connessione: ${e.message}');
        }
      }
      
      rethrow;
    }
  }

  Future<User?> register(Map<String, dynamic> data) async {
    try {
      await _apiService.register(data);
      return await login(data['email'], data['password']);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  Future<User?> getCurrentUser() async {
    try {
      final profileData = await _apiService.getProfile();
      return User.fromJson(profileData);
    } catch (e) {
      return null;
    }
  }
}