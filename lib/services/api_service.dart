import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/trip_models_admin.dart';
import '../screens/admin/trip_planning_screen.dart';

class ApiService {
  static const String _authBaseUrl = 'https://back-end-trip-build.vercel.app/api';
  static const String _adminBaseUrl = 'https://back-end-trip-build.vercel.app/api/admin';

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
    final response = await http.post(
      Uri.parse('$_authBaseUrl/login'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setToken(data['token']);
      return {
        'token': data['token'],
        'role': data['user']['role'],
        'name': data['user']['name'] ?? 'Admin',
      };
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to login');
    }
  }

  static Future<void> addDayToTrip({
    required String tripId,
    required String dayTitle,
    required String description,
    required String date,
  }) async {
    final response = await http.post(
      Uri.parse('$_adminBaseUrl/trips/$tripId/days'),
      headers: _headers,
      body: jsonEncode({
        'dayTitle': dayTitle,
        'description': description,
        'date': date,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to add day: ${response.body}');
    }
  }

  static Future<void> deleteSubFolder({
    required String tripId,
    required String dayId,
    required String folderId,
  }) async {
    final response = await http.delete(
      Uri.parse(
        '$_adminBaseUrl/trips/$tripId/days/$dayId/subfolders/$folderId',
      ),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete subfolder: ${response.body}');
    }
  }

  static Future<void> renameSubFolder({
    required String tripId,
    required String dayId,
    required String folderId,
    required String newName,
  }) async {
    final response = await http.put(
      Uri.parse(
        '$_adminBaseUrl/trips/$tripId/days/$dayId/subfolders/$folderId',
      ),
      headers: _headers,
      body: jsonEncode({'name': newName}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to rename subfolder: ${response.body}');
    }
  }

  static Future<void> deleteDocument(String documentId) async {
    final response = await http.delete(
      Uri.parse('$_adminBaseUrl/documents/$documentId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete document: ${response.body}');
    }
  }

  static Future<void> renameDocument(String documentId, String newName) async {
    final response = await http.put(
      Uri.parse('$_adminBaseUrl/documents/$documentId/rename'),
      headers: _headers,
      body: jsonEncode({'newName': newName}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to rename document: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> getDocumentDownloadUrl(
    String documentId,
  ) async {
    final response = await http.get(
      Uri.parse('$_adminBaseUrl/documents/$documentId/download'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get download URL: ${response.body}');
    }
  }

  static Future<void> updateDay({
    required String tripId,
    required String dayId,
    required String dayTitle,
    required String description,
  }) async {
    final response = await http.put(
      Uri.parse('$_adminBaseUrl/trips/$tripId/days/$dayId'),
      headers: _headers,
      body: jsonEncode({'dayTitle': dayTitle, 'description': description}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update day: ${response.body}');
    }
  }

  static Future<void> deleteDay({
    required String tripId,
    required String dayId,
  }) async {
    final response = await http.delete(
      Uri.parse('$_adminBaseUrl/trips/$tripId/days/$dayId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete day: ${response.body}');
    }
  }

  static Future<List<Client>> getAllClients() async {
    final response = await http.get(
      Uri.parse('$_adminBaseUrl/clients'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      if (data.isEmpty) {
        print('No clients found');
        return [];
      }

      return data
          .map((json) {
            try {
              return Client.fromJson(json);
            } catch (error) {
              print('Error processing client JSON: $error');
              return null;
            }
          })
          .where((client) => client != null)
          .cast<Client>()
          .toList();
    } else {
      throw Exception('Failed to load clients: ${response.body}');
    }
  }

  static Future<List<Trip>> getAllTrips() async {
    print('=== GET ALL TRIPS ===');

    try {
      final clients = await getAllClients();
      print('Found ${clients.length} clients');

      final List<Trip> allTrips = [];

      if (clients.isEmpty) {
        print('No clients found');
        return allTrips;
      }

      for (final client in clients) {
        try {
          final clientTrips = await getClientTrips(client.id, client);
          print('Client ${client.name} has ${clientTrips.length} trips');
          if (clientTrips.isNotEmpty) {
            allTrips.addAll(clientTrips);
          }
        } catch (error) {
          print('Error fetching trips for client ${client.id}: $error');
        }
      }

      print('Total trips found: ${allTrips.length}');
      return allTrips;
    } catch (error) {
      print('Error in getAllTrips: $error');
      return [];
    }
  }

  static Future<List<Trip>> getClientTrips(
    String clientId, [
    Client? client,
  ]) async {
    print('=== GET CLIENT TRIPS ===');
    print('Client ID: $clientId');

    final response = await http.get(
      Uri.parse('$_adminBaseUrl/clients/$clientId/trips'),
      headers: _headers,
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      print('Number of trips: ${data.length}');

      if (data.isEmpty) {
        print('No trips found for client $clientId');
        return [];
      }

      final clientToUse =
          client ??
          Client(
            id: clientId,
            name: 'Nom non disponible',
            email: 'Email non disponible',
            phone: 'Téléphone non disponible',
          );

      final trips =
          data
              .map((json) {
                try {
                  print('Processing trip JSON: $json');
                  final trip = Trip.fromJson(json, client: clientToUse);
                  print('Created trip with ID: ${trip.id}');
                  return trip;
                } catch (error) {
                  print('Error processing trip JSON: $error');
                  return null;
                }
              })
              .where((trip) => trip != null)
              .cast<Trip>()
              .toList();

      return trips;
    } else {
      throw Exception('Failed to load client trips: ${response.body}');
    }
  }

  static Future<Map<String, String>> createTripForExistingClient({
    required String clientId,
    required String tripDestination,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await http.post(
      Uri.parse('$_adminBaseUrl/trips/initiate'),
      headers: _headers,
      body: jsonEncode({
        'clientId': clientId,
        'trip': {
          'tripDestination': tripDestination,
          'startDate': startDate.toIso8601String().split('T')[0],
          'endDate': endDate.toIso8601String().split('T')[0],
        },
      }),
    );
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return {'tripId': data['tripId']};
    } else {
      throw Exception(
        'Failed to create trip for existing client: ${response.body}',
      );
    }
  }

  static Future<Map<String, String>> initiateTrip({
    required String clientName,
    required String clientEmail,
    required String clientPhone,
    required String clientPassword,
    required String tripDestination,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await http.post(
      Uri.parse('$_adminBaseUrl/trips/initiate'),
      headers: _headers,
      body: jsonEncode({
        'client': {
          'name': clientName,
          'email': clientEmail,
          'phone': clientPhone,
          'password': clientPassword,
        },
        'trip': {
          'tripDestination': tripDestination,
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        },
      }),
    );
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return {'clientId': data['clientId'], 'tripId': data['tripId']};
    } else {
      throw Exception('Failed to initiate trip: ${response.body}');
    }
  }

  static Future<void> planTrip({
    required String tripId,
    required List<DayPlan> dayPlans,
    required DateTime startDate,
  }) async {
    final response = await http.post(
      Uri.parse('$_adminBaseUrl/trips/$tripId/plan'),
      headers: _headers,
      body: jsonEncode({
        'startDate': startDate.toIso8601String(),
        'days':
            dayPlans
                .map(
                  (plan) => {
                    'dayTitle': plan.title,
                    'description': plan.description,
                  },
                )
                .toList(),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to save trip plan: ${response.body}');
    }
  }

  static Future<Trip> getTripDetails(String tripId) async {
    final response = await http.get(
      Uri.parse('$_adminBaseUrl/trips/$tripId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);

      final client = Client(
        id: data['clientId'] ?? '',
        name: data['clientName'] ?? 'Nom non disponible',
        email: data['clientEmail'] ?? 'Email non disponible',
        phone: data['clientPhone'] ?? 'Téléphone non disponible',
      );

      final tripData = Map<String, dynamic>.from(data);
      tripData['client'] = client.toJson();

      return Trip.fromJson(tripData, client: client);
    } else {
      throw Exception('Failed to load trip details: ${response.body}');
    }
  }

  static Future<void> addSubFolderToDay({
    required String tripId,
    required String dayId,
    required String name,
    required String icon,
    required String color,
  }) async {
    final response = await http.post(
      Uri.parse('$_adminBaseUrl/trips/$tripId/days/$dayId/subfolders'),
      headers: _headers,
      body: jsonEncode({'name': name, 'icon': icon, 'color': color}),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to add subfolder: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> updateClient({
    required String clientId,
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
      Uri.parse('$_adminBaseUrl/clients/$clientId'),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(
        errorData['message'] ?? 'Failed to update client: ${response.body}',
      );
    }
  }

  static Future<Map<String, dynamic>> uploadDocument({
    required String tripId,
    required String dayId,
    required String folderId,
    required PlatformFile file,
  }) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$_adminBaseUrl/trips/$tripId/documents'),
    );

    request.headers['Authorization'] = 'Bearer $_token';
    request.fields['dayId'] = dayId;
    request.fields['folderId'] = folderId;

    request.files.add(
      http.MultipartFile.fromBytes(
        'document',
        file.bytes!,
        filename: file.name,
      ),
    );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode != 201) {
      throw Exception('Failed to upload document: $responseBody');
    }

    try {
      final Map<String, dynamic> data = jsonDecode(responseBody);
      return data;
    } catch (_) {
      // In case backend returns non-JSON unexpectedly
      return {'message': 'File uploaded successfully'};
    }
  }

  static Future<void> deleteClient(String clientId) async {
    final response = await http.delete(
      Uri.parse('$_adminBaseUrl/clients/$clientId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(
        errorData['message'] ?? 'Failed to delete client: ${response.body}',
      );
    }
  }

  static Future<void> updateTrip({
    required String tripId,
    required String destination,
    required String status,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await http.put(
      Uri.parse('$_adminBaseUrl/trips/$tripId'),
      headers: _headers,
      body: jsonEncode({
        'tripDestination': destination,
        'status': status,
        'startDate': startDate.toIso8601String().split('T')[0],
        'endDate': endDate.toIso8601String().split('T')[0],
      }),
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(
        errorData['message'] ?? 'Failed to update trip: ${response.body}',
      );
    }
  }

  static Future<void> deleteTrip(String tripId) async {
    final response = await http.delete(
      Uri.parse('$_adminBaseUrl/trips/$tripId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(
        errorData['message'] ?? 'Failed to delete trip: ${response.body}',
      );
    }
  }

  static Future<void> blockClient(String clientId) async {
    await deleteClient(clientId);
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

  static Future<Map<String, dynamic>> getAdminProfile() async {
    final response = await http.get(
      Uri.parse('$_adminBaseUrl/profile'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load admin profile: ${response.body}');
    }
  }

  static Future<void> updateAdminProfile({
    required String name,
    required String email,
    String? password,
  }) async {
    final Map<String, dynamic> body = {'name': name, 'email': email};

    if (password != null && password.trim().isNotEmpty) {
      body['password'] = password;
    }

    final response = await http.put(
      Uri.parse('$_adminBaseUrl/profile'),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(
        errorData['message'] ??
            'Failed to update admin profile: ${response.body}',
      );
    }
  }

  static Future<Map<String, dynamic>> createAdmin({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_adminBaseUrl/create'),
      headers: _headers,
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(
        errorData['message'] ?? 'Failed to create admin: ${response.body}',
      );
    }
  }
}
