import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  
  final SupabaseClient _supabaseClient;
  final FlutterSecureStorage _secureStorage;
  
  AuthService({
    required SupabaseClient supabaseClient,
    required FlutterSecureStorage secureStorage,
  }) : _supabaseClient = supabaseClient,
       _secureStorage = secureStorage;
  
  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final session = _supabaseClient.auth.currentSession;
    if (session != null) {
      return true;
    }
    
    // Check if we have tokens in secure storage
    try {
      final token = await _secureStorage.read(key: _tokenKey);
      return token != null;
    } catch (e) {
      debugPrint('Error checking login status: $e');
      return false;
    }
  }
  
  // Get current user ID
  Future<String?> getUserId() async {
    final user = _supabaseClient.auth.currentUser;
    if (user != null) {
      return user.id;
    }
    
    // Try to get from secure storage
    try {
      return await _secureStorage.read(key: _userIdKey);
    } catch (e) {
      debugPrint('Error getting user ID: $e');
      return null;
    }
  }
  
  // Get auth token for API calls
  Future<String?> getAuthToken() async {
    final session = _supabaseClient.auth.currentSession;
    if (session != null) {
      return session.accessToken;
    }
    
    // Try to get from secure storage
    try {
      return await _secureStorage.read(key: _tokenKey);
    } catch (e) {
      debugPrint('Error getting auth token: $e');
      return null;
    }
  }
  
  // Get current token synchronously (for sync service)
  String? getCurrentToken() {
    final session = _supabaseClient.auth.currentSession;
    return session?.accessToken;
  }
  
  // Login with email and password
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      // Store tokens in secure storage
      if (response.session != null) {
        await _secureStorage.write(
          key: _tokenKey,
          value: response.session!.accessToken,
        );
        await _secureStorage.write(
          key: _refreshTokenKey,
          value: response.session!.refreshToken,
        );
        await _secureStorage.write(
          key: _userIdKey,
          value: response.user?.id,
        );
      }
      
      return response;
    } catch (e) {
      debugPrint('Login error: $e');
      rethrow;
    }
  }
  
  // Register new user
  Future<AuthResponse> register({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabaseClient.auth.signUp(
        email: email,
        password: password,
      );
      
      // Store tokens in secure storage
      if (response.session != null) {
        await _secureStorage.write(
          key: _tokenKey,
          value: response.session!.accessToken,
        );
        await _secureStorage.write(
          key: _refreshTokenKey,
          value: response.session!.refreshToken,
        );
        await _secureStorage.write(
          key: _userIdKey,
          value: response.user?.id,
        );
      }
      
      return response;
    } catch (e) {
      debugPrint('Registration error: $e');
      rethrow;
    }
  }
  
  // Logout
  Future<void> logout() async {
    try {
      await _supabaseClient.auth.signOut();
      
      // Clear secure storage
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      await _secureStorage.delete(key: _userIdKey);
    } catch (e) {
      debugPrint('Logout error: $e');
      rethrow;
    }
  }
  
  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabaseClient.auth.resetPasswordForEmail(email);
    } catch (e) {
      debugPrint('Reset password error: $e');
      rethrow;
    }
  }
}
