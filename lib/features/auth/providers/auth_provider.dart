import 'dart:async';

import 'package:alemedu_app/core/models/user_model.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:alemedu_app/core/services/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  final _storage = const FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  UserModel? _user;
  String? _token;
  String? _error;
  bool _isLoading = false;
  
  // تخزين مؤقت للبيانات لتجنب القراءة المتكررة من التخزين
  String? _cachedToken;
  Map<String, dynamic>? _cachedUserData;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get error => _error; // Added to the getter

  // تم إزالة الدوال المساعدة والدوال الثابتة غير المستخدمة

  Future<void> loadStoredToken() async {
    // استخدام التخزين المؤقت إذا كان متوفراً
    if (_cachedToken != null) {
      _token = _cachedToken;
      if (_token != null) {
        ApiService().addTokenToHeaders(_token!);
      }
      return;
    }
    
    try {
      final token = await _storage.read(key: 'token');
      _token = token;
      _cachedToken = token; // تخزين في الذاكرة المؤقتة
      if (_token != null) {
        ApiService().addTokenToHeaders(_token!);
      }
    } catch (e) {
      if (kDebugMode) {
        print('خطأ في تحميل التوكن: $e');
      }
    }
  }

  Future<Map<String, dynamic>?> _handleRequest(
      Future<Map<String, dynamic>?> Function() request) async {
    try {
      final response = await request();
      return response;
    } catch (e, stack) {
      if (kDebugMode) {
        print('Error: $e');
        print(stack);
      }

      if (e is UnauthorizedException) {
        final refreshedToken = await _refreshToken();
        if (refreshedToken != null) {
          _apiService.addTokenToHeaders(refreshedToken);
          return await request();
        }
      } else {
        rethrow;
      }
      rethrow;
    }
  }

  Future<String?> _refreshToken() async {
    final response = await _apiService.post('/refresh', {'token': _token});
    if (response != null &&
        response['status'] == true &&
        response['data'] != null) {
      final data = response['data'];
      final newToken = data['token'];
      _token = newToken;
      _cachedToken = newToken; // تخزين في الذاكرة المؤقتة
      // كتابة التوكن مباشرة
      await _storage.write(key: 'token', value: newToken);
      return newToken;
    }
    return null;
  }

  Future<bool> signInWithGoogle() async {
    _error = null;
    notifyListeners();

    _isLoading = true;
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _error = 'تم إلغاء تسجيل الدخول عبر Google';
        notifyListeners();
        return false;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      String serverClientId =
          "629802140732-27a6f8bel525n2vdj6o375o5s1s9rrrk.apps.googleusercontent.com";
      // إرسال البيانات إلى الخادم
      // معالجة URL الصورة الشخصية لتجنب مشكلة التخزين المزدوج
      String? photoUrl = googleUser.photoUrl;
      if (photoUrl != null && photoUrl.startsWith('https://')) {
        photoUrl = "EXTERNAL_URL:$photoUrl";
      }
      final Map<String, dynamic>? response = await _handleRequest(() async =>
          await _apiService.post('/login/google', {
            'id_token': googleAuth.idToken,
            'access_token': googleAuth.accessToken,
            'email': googleUser.email,
            'name': googleUser.displayName,
            'photo': photoUrl,
            'google_id': googleUser.id, // إضافة معرف جوجل
            'provider': 'google', // تحديد المزود
            'device_type': 'android', // نوع الجهاز
            'external_photo': true, // علامة للإشارة إلى أن الصورة خارجية,
            'server_client_id': serverClientId
          }));
      if (response != null &&
          response['status'] == true &&
          response['data'] != null) {
        final data = response['data'];
        if (data['token'] != null) {
          _token = data['token'];
          _apiService.addTokenToHeaders(_token!);
        }

        if (data['token'] != null && data['user'] != null) {
          _token = data['token'];

          await _storage.write(key: 'token', value: _token); // كتابة التوكن في الخيط الرئيسي
          _user = UserModel.fromJson(data['user']);
          await setCurrentUser(_user!);
          notifyListeners();
          return true;
        }
      }

      _error = response?['message'] ?? 'حدث خطأ أثناء تسجيل الدخول';
      notifyListeners();
      return false;
    } catch (e, stack) {
      _error = 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.';
      if (kDebugMode) {
        print(e);
        print(stack);
      }
      notifyListeners();

      return false;
    } finally {
      _isLoading = false;
       notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _error = null;
    notifyListeners();
    _isLoading = true;
    try {
      final Map<String, dynamic>? response = await _handleRequest(() async =>
          await _apiService.post('/login', {
            'email': email,
            'password': password,
          }));

      if (response != null &&
          response['status'] == true &&
          response['data'] != null) {
        final data = response['data'];
        if (data['token'] != null && data['user'] != null) {
          _token = data['token'];
          _cachedToken = _token; // تخزين في الذاكرة المؤقتة
          _apiService.addTokenToHeaders(_token!);
          // كتابة التوكن مباشرة
          await _storage.write(key: 'token', value: _token!);
          _user = UserModel.fromJson(data['user']);

          await setCurrentUser(_user!);

          notifyListeners();
          return true;
        } else {
          if (kDebugMode) {
            print('Token or user data not found in the response: $data');
          }
        }
      } 
     
      _error = response?['message'] ?? 'خطأ في البريد الإلكتروني أو كلمة المرور';
      notifyListeners();
      return false;
    } catch (e, stack) {
      if (kDebugMode) {
        print('Error: $e');
        print(stack);
      }
      _error = 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.';
      notifyListeners();
      return false;
    } finally {
        _isLoading = false;
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    _error = null;
    notifyListeners();

      _isLoading = true;
    try {
      final Map<String, dynamic>? response = await _handleRequest(() async =>
          await _apiService.post('/auth/forgot-password', {
            'email': email,
          }));
      if (response != null &&
          response['status'] == true &&
          response['data'] != null) {
          
        notifyListeners();
        return true;
      }
        _error = response?['message'] ?? 'فشل ارسال رسالة اعادة تعيين كلمة المرور';
        notifyListeners();
        return false;
    } catch (e, stack) {
      if (kDebugMode) {
        print('Error: $e');
        print(stack);
      }
      _error = 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.';
      notifyListeners();
      return false;
    } finally {
       _isLoading = false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _error = null;
    notifyListeners();
     _isLoading = true;
    try {
      final Map<String, dynamic>? response = await _handleRequest(() async =>
          await _apiService.post('/register', {
            'name': name,
            'email': email,
            'password': password,
            'password_confirmation': password,
          }));
      if (response != null &&
          response['status'] == true &&
          response['data'] != null) {
        final data = response['data'];
        if (data['token'] != null && data['user'] != null) {
          _token = data['token'];
          _cachedToken = _token; // تخزين في الذاكرة المؤقتة
          _apiService.addTokenToHeaders(_token!);

          // كتابة التوكن مباشرة
          await _storage.write(key: 'token', value: _token!);
          _user = UserModel.fromJson(data['user']);
          await setCurrentUser(_user!);
          notifyListeners();
          return true;
        }
      }
      _error = response?['message'] ?? 'فشل التسجيل. يرجى المحاولة مرة أخرى.';
      notifyListeners();
      return false;
    } catch (e, stack) {
      if (kDebugMode) {
        print('Error: $e');
        print(stack);
      }
      _error = 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.';

      notifyListeners();
      return false;
    } finally {
       _isLoading = false;
    }
  }

  Future<void> setCurrentUser(UserModel user) async {
    final userData = jsonEncode(user.toJson());
    _cachedUserData = user.toJson(); // تخزين في الذاكرة المؤقتة
    // كتابة بيانات المستخدم مباشرة
    await _storage.write(key: 'user', value: userData);
  }

  Future<void> loadStoredUser() async {
    await loadStoredToken();
    
    // استخدام البيانات المخزنة مؤقتاً إذا كانت متوفرة
    if (_cachedUserData != null) {
      _user = UserModel.fromJson(_cachedUserData!);
      notifyListeners();
      return;
    }
    
    try {
      final storedUser = await _storage.read(key: 'user');
      if (storedUser != null) {
        final userData = jsonDecode(storedUser);
        _cachedUserData = userData; // تخزين في الذاكرة المؤقتة
        _user = UserModel.fromJson(userData);
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('خطأ في تحميل بيانات المستخدم: $e');
      }
    }
  }

  Future<void> logout() async {
    // مسح البيانات من التخزين الآمن مباشرة
    await _storage.deleteAll();
    
    // مسح البيانات من الذاكرة المؤقتة
    _cachedToken = null;
    _cachedUserData = null;
    _user = null;
    _apiService.removeTokenFromHeaders();
    _token = null;
    notifyListeners();
  }
}
