import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; 
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException({required this.message, this.statusCode});

  @override
  String toString() => message;
}

class UnauthorizedException implements Exception {
  final String message;

  UnauthorizedException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  // Make ApiService singleton
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Constants.
  static const String baseUrl = 'https://alemedu.com/api';
  static const String _apiKeyStorageKey = 'api_key';
  static const String _validApiKey = 'gfOTaGfOcVZigVyN3Go5ZHwr606mmzlPs6gfet0Nsd6d5wBykGGsI9rf1zZ0UYsZ';
  // Private fields.
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  //get storage instance.
  FlutterSecureStorage get storage => _storage;
  
  // Cache for API key to avoid frequent disk reads
  String? _cachedApiKey;
  String? _cachedToken;

  String? _token; // Store the current token

  // Methods to manage the token
  void addTokenToHeaders(String token) {
    _token = token;
  }

  void removeTokenFromHeaders() {
    _token = null;
  }

  // تهيئة ApiService والتحقق من وجود API Key
  // This function is called only once at app start

  Future<void> initialize() async {    
    // استخدام قراءة مباشرة بدلاً من compute لتجنب مشاكل التهيئة
    try {
      final storedApiKey = await _storage.read(key: _apiKeyStorageKey);
      if (storedApiKey == null || storedApiKey.isEmpty) {
        await _storage.write(key: _apiKeyStorageKey, value: _validApiKey);
        _cachedApiKey = _validApiKey;
      } else {
        _cachedApiKey = storedApiKey;
      }
      
      // تخزين القيمة في الذاكرة المؤقتة لتجنب القراءة المتكررة
      _cachedApiKey = _cachedApiKey ?? _validApiKey;
    } catch (e) {
      print('خطأ في تهيئة API Key: $e');
      // استخدام القيمة الافتراضية في حالة الخطأ
      _cachedApiKey = _validApiKey;
    }
  }
  
  // تم إزالة الدوال الثابتة غير المستخدمة

    Future<String?> getToken() async {
      if (_token != null) return _token;
      if (_cachedToken != null) return _cachedToken;
      
      try {
        // استخدام قراءة مباشرة بدلاً من compute لتجنب مشاكل التهيئة
        final token = await _storage.read(key: 'token');
        _cachedToken = token;
        return token;
      } catch (e) {
        print('خطأ في قراءة التوكن: $e');
        return null;
      }
    }

  // التحقق من صلاحية API Key
  Future<bool> validateApiKey(String apiKey) async {
    return apiKey == _validApiKey;
  }

  Future<String> getApiKey() async {
    try {
      // إذا كان المفتاح موجود في الذاكرة المؤقتة، استخدمه مباشرة
      if (_cachedApiKey != null && _cachedApiKey!.isNotEmpty) {
        return _cachedApiKey!;
      }
      
      // The correct API key provided by the server
      const correctApiKey = 'gfOTaGfOcVZigVyN3Go5ZHwr606mmzlPs6gfet0Nsd6d5wBykGGsI9rf1zZ0UYsZ';

      // استخدام قراءة مباشرة بدلاً من compute
      final apiKey = await _storage.read(key: _apiKeyStorageKey);
      
      // استخدام SharedPreferences بشكل مباشر
      final prefs = await SharedPreferences.getInstance();
      final prefsApiKey = prefs.getString('apiKey');

      // Check if API key exists in shared preferences
      if (prefsApiKey != null && prefsApiKey.isNotEmpty) {
        // Also store it in secure storage for consistency
        await _storage.write(key: _apiKeyStorageKey, value: prefsApiKey);
        _cachedApiKey = prefsApiKey;
        return prefsApiKey;
      }
      
      // If API key is found in secure storage, store it in shared preferences too, and use it.
      if (apiKey != null && apiKey.isNotEmpty) {        
        // Store it in shared preferences too
        await prefs.setString('apiKey', apiKey);
        _cachedApiKey = apiKey;
        return apiKey;    
      } else {
        // Store the correct key in both storages for future use
        await _storage.write(key: _apiKeyStorageKey, value: correctApiKey);
        await prefs.setString('apiKey', correctApiKey);
        
        _cachedApiKey = correctApiKey;
        return correctApiKey;
      }
    } catch (e) {
      print('خطأ في الحصول على API Key: $e');
      // Fallback to the correct API key in case of any errors.
      const correctApiKey = 'gfOTaGfOcVZigVyN3Go5ZHwr606mmzlPs6gfet0Nsd6d5wBykGGsI9rf1zZ0UYsZ';
      
      // حفظ المفتاح في الذاكرة المؤقتة
      _cachedApiKey = correctApiKey;
      
      // محاولة تخزينه في SharedPreferences كملاذ أخير
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('apiKey', correctApiKey);
      } catch (e) {
        print('فشل تخزين API key في SharedPreferences: $e');
      }
      
      return correctApiKey;
    }
  }
  
  // تم إزالة الدوال الثابتة الإضافية غير المستخدمة

  Future<Map<String, String>> getHeaders({bool isMultipart = false}) async {    
    try {
      final String apiKey = await getApiKey(); // Check if the api key is valid or not.
      final Map<String, String> headers = {
        if (!isMultipart) 'Content-Type': 'application/json', // Add content type if it is not multipart.
        'Accept': 'application/json',
        'X-API-KEY': apiKey,
      };
      if(_token != null){
        headers['Authorization'] = 'Bearer $_token';
      }
      return headers;
    } catch (e) {
      if (e is UnauthorizedException) {
        // يمكنك هنا تنفيذ إجراءات إضافية مثل تسجيل الخروج
        rethrow;
      }
      throw ApiException(
        message: 'خطأ في التحقق من الصلاحية',
        statusCode: 401,
      );
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final headers = await getHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: json.encode(data),
      );

      print('📥 Response status code: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      // Handle UnauthorizedException (401) for login endpoints
      if (response.statusCode == 401) {
        try {
          final responseData = json.decode(response.body);          
          if (endpoint == '/login' || endpoint == '/login/google') { // Check if it's a login request
            return responseData; // Return error message
          } else {
            throw UnauthorizedException(responseData['message'] ?? 'انتهت صلاحية الجلسة'); // Throw UnauthorizedException for other endpoints
          }
        } catch (e) { // If failed to parse the body
          if (endpoint == '/login' || endpoint == '/login/google') { // Check if it's a login request
            return {'status': false,'message': 'خطأ في البريد الإلكتروني أو كلمة المرور'}; // Return default error message for login
          } else {
            throw UnauthorizedException('انتهت صلاحية الجلسة');
          }
        }
      }
      
      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200 || response.statusCode == 201) { // Success
        return responseData;
      } else {
        throw ApiException( // Error
          message: responseData['message'] ?? 'حدث خطأ في العملية', 
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('💥 API Error: $e');
      if (e is UnauthorizedException) rethrow;
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'حدث خطأ في الاتصال بالخادم',
        statusCode: 500,
      );      
    }
  }

  Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParameters}) async {
    try {

      final headers = await getHeaders();
      
      var uri = Uri.parse('$baseUrl$endpoint');
      if (queryParameters != null) {
        uri = uri.replace(queryParameters: queryParameters.map((key, value) => MapEntry(key, value.toString())));
      }

      final response = await http.get(
        uri,
        headers: headers,
      );
      
      print('📥 Response status code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);
          return responseData;
        } catch (e) {
          throw ApiException(            
            message: 'خطأ في تنسيق البيانات من الخادم',            
            statusCode: response.statusCode,
          );
        }
      } else {

        try { // Try to parse error message
          final errorData = json.decode(response.body);
          throw ApiException(
            message: errorData['message'] ?? 'حدث خطأ في العملية',
            statusCode: response.statusCode,
          );
        } catch (e) {
          throw ApiException(
            message: 'حدث خطأ في العملية',
            statusCode: response.statusCode,
          );
        }
      }
    } catch (e) {
      print('💥 API Error: $e');
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        message: 'حدث خطأ في الاتصال بالخادم',
        statusCode: 500,
      );
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final headers = await getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: json.encode(data),
      );
      
      final responseData = json.decode(response.body); // Parse response body.
      
      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw ApiException(
          message: responseData['message'] ?? 'حدث خطأ في العملية',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        message: 'حدث خطأ في الاتصال بالخادم',
        statusCode: 500,
      );
    }
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> data) async {
    try {
      final headers = await getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: json.encode(data),        
      );
      
      print('📥 Response status code: ${response.statusCode}'); 
      print('📥 Response body: ${response.body}');
      
      final responseData = json.decode(response.body); // Parse response body.
      
      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw ApiException(
          message: responseData['message'] ?? 'حدث خطأ في العملية',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('💥 API Error: $e');
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        message: 'حدث خطأ في الاتصال بالخادم',
        statusCode: 500,
      );
    }
  }

  Future<dynamic> uploadFile(String endpoint, File file, String fieldName) async {
    try {
      final headers = await getHeaders(isMultipart: true);
      final uri = Uri.parse('$baseUrl$endpoint');      

      // Create and configure multipart request
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll(headers)
        ..files.add(await http.MultipartFile.fromPath(
          fieldName,          file.path,
        ));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse); // Get response.


      print('📄 محتوى الاستجابة: ${response.body}');
      
      final responseData = json.decode(response.body); // Parse response body.
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseData;
      } else {
        throw ApiException(          
          message: responseData['message'] ?? 'حدث خطأ غير متوقع',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {

      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>?> delete(String endpoint) async {
    try {
      final headers = await getHeaders();

      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );


      print('📄 محتوى الاستجابة: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('غير مصرح');
      } else {
        final errorBody = json.decode(response.body);
        throw ApiException(
          message: errorBody['message'] ?? 'حدث خطأ غير متوقع',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {

      rethrow;
    }
  }
  //get the stored user data from local storage.
  Future<Map<String, dynamic>> getCurrentUserData() async {
    try {
      // استخدام قراءة مباشرة بدلاً من compute
      final userData = await _storage.read(key: 'user_data');
      if (userData != null) {
        return json.decode(userData);
      }
    } catch (e) {
      print('خطأ في قراءة بيانات المستخدم: $e');
    }
    
    // إرجاع بيانات مستخدم افتراضية إذا لم تكن متوفرة
    return {
      'id': 0,
      'name': 'مستخدم',
      'email': '',
      'avatar': null,
    };
  }
}
