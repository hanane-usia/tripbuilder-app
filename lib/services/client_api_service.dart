import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/trip_models.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class ClientApiService {
  static const String _baseUrl =
      'https://back-end-trip-build.vercel.app/api/client';

  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json; charset=UTF-8',
    'Authorization': 'Bearer $_token',
  };

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    print('🌐 Making client login request to: $_baseUrl/login');
    print('📧 Email: $email');
    print('🔑 Password length: ${password.length}');

    late http.Response response;
    try {
      response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'email': email, 'password': password}),
      );
    } catch (e) {
      print('❌ Network error during login: $e');
      print('🔍 Error type: ${e.runtimeType}');
      throw Exception('Network error: $e');
    }

    print('📡 Client login response status: ${response.statusCode}');
    print('📄 Client login response body: ${response.body}');
    print('📋 Response headers: ${response.headers}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setToken(data['token']);
      print('✅ Client token set successfully');
      // After login, register FCM token
      try {
        print('🔔 Getting FCM token...');
        final fcmToken = await FirebaseMessaging.instance.getToken();
        print(
          '🔔 FCM Token received: ${fcmToken != null ? fcmToken.substring(0, 20) + '...' : 'null'}',
        );

        if (fcmToken != null) {
          print('🔔 Registering FCM token to backend...');
          await _registerFcmToken(fcmToken);
          print('✅ FCM token registered to backend');
        } else {
          print(
            '⚠️ No FCM token available - notifications may not work properly',
          );
        }
      } catch (e) {
        print('❌ Failed to register FCM token: $e');
        print(
          '⚠️ This is not critical - the app will continue to work without push notifications',
        );
      }
      return {'token': data['token'], 'client': data['client']};
    } else {
      final errorData = jsonDecode(response.body);
      print('❌ Client login error: ${errorData['message']}');
      throw Exception(errorData['message'] ?? 'Failed to login');
    }
  }

  static Future<void> _registerFcmToken(String token) async {
    print('🔔 Sending FCM token to backend: $_baseUrl/fcm-token');
    print('🔔 Headers: $_headers');

    final response = await http.post(
      Uri.parse('$_baseUrl/fcm-token'),
      headers: _headers,
      body: jsonEncode({'token': token}),
    );

    print('🔔 FCM token response status: ${response.statusCode}');
    print('🔔 FCM token response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to save FCM token: ${response.body}');
    }
  }

  static Future<Client> getClientProfile() async {
    print('🌐 Making client profile request to: $_baseUrl/profile');
    print('🔑 Headers: $_headers');

    final response = await http.get(
      Uri.parse('$_baseUrl/profile'),
      headers: _headers,
    );

    print('📡 Client profile response status: ${response.statusCode}');
    print('📄 Client profile response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('✅ Client profile data received');
      return Client.fromJson(data);
    } else {
      print('❌ Client profile error: ${response.body}');
      throw Exception('Failed to load client profile: ${response.body}');
    }
  }

  static Future<List<Trip>> getClientTrips() async {
    print('🌐 Making API call to: $_baseUrl/trips');
    print('🔑 Headers: $_headers');

    final response = await http.get(
      Uri.parse('$_baseUrl/trips'),
      headers: _headers,
    );

    print('📡 Response status: ${response.statusCode}');
    print('📄 Response body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      print('📊 Parsed ${data.length} trips from API');
      return data.map((json) => Trip.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load client trips: ${response.body}');
    }
  }

  static Future<Trip> getTripDetails(String tripId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/trips/$tripId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Trip.fromJson(data);
    } else {
      throw Exception('Failed to load trip details: ${response.body}');
    }
  }

  static Future<List<TripDay>> getTripDays(String tripId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/trips/$tripId/days'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => TripDay.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load trip days: ${response.body}');
    }
  }

  static Future<List<TripEvent>> getDayEvents(
    String tripId,
    String dayId,
  ) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/trips/$tripId/days/$dayId/events'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => TripEvent.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load day events: ${response.body}');
    }
  }

  static Future<List<SubFolder>> getDaySubFolders(
    String tripId,
    String dayId,
  ) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/trips/$tripId/days/$dayId/subfolders'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => SubFolder.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load day subfolders: ${response.body}');
    }
  }

  static Future<void> updateProfile({
    required String name,
    required String email,
    required String phone,
    String? password,
  }) async {
    final Map<String, dynamic> body = {
      'name': name,
      'email': email,
      'phone': phone,
    };

    if (password != null && password.trim().isNotEmpty) {
      body['password'] = password;
    }

    final response = await http.put(
      Uri.parse('$_baseUrl/profile'),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(
        errorData['message'] ?? 'Failed to update profile: ${response.body}',
      );
    }
  }

  static Future<void> logout() async {
    final response = await http.post(
      Uri.parse('$_baseUrl/logout'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      _token = null;
    }
  }

  static Future<Map<String, dynamic>> getDocumentDownloadUrl(
    String documentId,
  ) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/documents/$documentId/download'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get download URL: ${response.body}');
    }
  }

  static Future<String> downloadFile(
    String downloadUrl,
    String fileName,
  ) async {
    final response = await http.get(Uri.parse(downloadUrl));

    if (response.statusCode == 200) {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes);
      return file.path;
    } else {
      throw Exception('Failed to download file: ${response.statusCode}');
    }
  }

  static Future<bool> checkFirstLogin() async {
    print('🔍 Checking first login...');
    print('🌐 Making request to: $_baseUrl/first-login');
    print('🔑 Headers: $_headers');

    final response = await http.get(
      Uri.parse('$_baseUrl/first-login'),
      headers: _headers,
    );

    print('📡 First login response status: ${response.statusCode}');
    print('📄 First login response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final isFirstLogin = data['isFirstLogin'] ?? false;
      print('✅ First login check result: $isFirstLogin');
      return isFirstLogin;
    } else {
      print('❌ First login check error: ${response.body}');
      throw Exception('Failed to check first login: ${response.body}');
    }
  }

  static Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/change-password'),
      headers: _headers,
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode == 200) {
      return;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(
        errorData['message'] ?? 'Failed to change password: ${response.body}',
      );
    }
  }

  // Forgot Password Methods
  static Future<Map<String, dynamic>> sendOTP(
    String email,
    String userType,
  ) async {
    print('🔐 Sending OTP for email: $email, userType: $userType');

    final response = await http.post(
      Uri.parse(
        'https://back-end-trip-build.vercel.app/api/forgot-password/send-otp',
      ),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'email': email, 'userType': userType}),
    );

    print('🔐 Send OTP response status: ${response.statusCode}');
    print('🔐 Send OTP response body: ${response.body}');

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {
        'success': true,
        'message': data['message'],
        'email': data['email'],
        'userType': data['userType'],
      };
    } else {
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to send OTP',
      };
    }
  }

  static Future<Map<String, dynamic>> verifyOTP(
    String email,
    String otpCode,
    String userType,
  ) async {
    print('🔐 Verifying OTP for email: $email, userType: $userType');

    final response = await http.post(
      Uri.parse(
        'https://back-end-trip-build.vercel.app/api/forgot-password/verify-otp',
      ),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'email': email,
        'otpCode': otpCode,
        'userType': userType,
      }),
    );

    print('🔐 Verify OTP response status: ${response.statusCode}');
    print('🔐 Verify OTP response body: ${response.body}');

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {
        'success': true,
        'message': data['message'],
        'email': data['email'],
        'userType': data['userType'],
      };
    } else {
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to verify OTP',
      };
    }
  }

  static Future<Map<String, dynamic>> resetPassword(
    String email,
    String otpCode,
    String newPassword,
    String userType,
  ) async {
    print('🔐 Resetting password for email: $email, userType: $userType');

    final response = await http.post(
      Uri.parse(
        'https://back-end-trip-build.vercel.app/api/forgot-password/reset-password',
      ),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'email': email,
        'otpCode': otpCode,
        'newPassword': newPassword,
        'userType': userType,
      }),
    );

    print('🔐 Reset password response status: ${response.statusCode}');
    print('🔐 Reset password response body: ${response.body}');

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {
        'success': true,
        'message': data['message'],
        'email': data['email'],
      };
    } else {
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to reset password',
      };
    }
  }

  static Future<Map<String, dynamic>> resendOTP(
    String email,
    String userType,
  ) async {
    print('🔐 Resending OTP for email: $email, userType: $userType');

    final response = await http.post(
      Uri.parse(
        'https://back-end-trip-build.vercel.app/api/forgot-password/resend-otp',
      ),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'email': email, 'userType': userType}),
    );

    print('🔐 Resend OTP response status: ${response.statusCode}');
    print('🔐 Resend OTP response body: ${response.body}');

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {
        'success': true,
        'message': data['message'],
        'email': data['email'],
        'userType': data['userType'],
      };
    } else {
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to resend OTP',
      };
    }
  }
}
