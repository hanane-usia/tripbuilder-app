import 'package:flutter/material.dart';

// Ce fichier contient les modèles simplifiés pour la vue client
// Les modèles complets avec fromJson sont dans trip_models_admin.dart

class TripEvent {
  final String id;
  final String title;
  final String location;
  final IconData icon;
  final Color color;

  TripEvent({
    required this.id,
    required this.title,
    required this.location,
    required this.icon,
    required this.color,
  });

  factory TripEvent.fromJson(Map<String, dynamic> json) {
    return TripEvent(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      location: json['location'] ?? '',
      icon: _getIconFromString(json['icon'] ?? 'event'),
      color: _getColorFromString(json['color'] ?? '#3B82F6'),
    );
  }

  static IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'flight_land':
        return Icons.flight_land;
      case 'directions_car':
        return Icons.directions_car;
      case 'restaurant':
        return Icons.restaurant;
      case 'account_balance':
        return Icons.account_balance;
      case 'beach_access':
        return Icons.beach_access;
      case 'restaurant_menu':
        return Icons.restaurant_menu;
      case 'train':
        return Icons.train;
      case 'park':
        return Icons.park;
      case 'nightlife':
        return Icons.nightlife;
      case 'breakfast_dining':
        return Icons.breakfast_dining;
      case 'airport_shuttle':
        return Icons.airport_shuttle;
      case 'flight_takeoff':
        return Icons.flight_takeoff;
      default:
        return Icons.event;
    }
  }

  static Color _getColorFromString(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF3B82F6);
    }
  }
}

class Trip {
  final String id;
  final Client client;
  final String tripDestination;
  final DateTime startDate;
  final DateTime endDate;
  final List<TripDay> days;
  final String status;

  Trip({
    required this.id,
    required this.client,
    required this.tripDestination,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.status,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    print('🔍 Parsing Trip from JSON: ${json.keys}');

    // Handle date parsing more safely
    DateTime parseDate(String? dateString) {
      if (dateString == null || dateString.isEmpty) {
        return DateTime.now();
      }
      try {
        return DateTime.parse(dateString);
      } catch (e) {
        print('⚠️ Error parsing date: $dateString, using current date');
        return DateTime.now();
      }
    }

    return Trip(
      id: json['id'] ?? json['tripId'] ?? '',
      client: Client.fromJson(json['client'] ?? {}),
      tripDestination: json['tripDestination'] ?? '',
      startDate: parseDate(json['startDate']),
      endDate: parseDate(json['endDate']),
      status: json['status'] ?? 'active',
      days:
          (json['days'] as List<dynamic>? ?? [])
              .map((dayJson) => TripDay.fromJson(dayJson))
              .toList(),
    );
  }
}

class Client {
  final String id;
  final String name;
  final String email;
  final String phone;

  Client({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    print('🔍 Parsing Client from JSON: ${json.keys}');
    return Client(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}

class TripDay {
  final String id;
  final String dayTitle;
  final String date;
  final String description;
  final List<SubFolder> subFolders;
  final List<TripEvent> events;

  TripDay({
    required this.id,
    required this.dayTitle,
    required this.date,
    required this.description,
    required this.subFolders,
    required this.events,
  });

  factory TripDay.fromJson(Map<String, dynamic> json) {
    return TripDay(
      id: json['id'] ?? json['dayId'] ?? '',
      dayTitle: json['dayTitle'] ?? '',
      date: json['date'] ?? '',
      description: json['description'] ?? '',
      subFolders:
          (json['subFolders'] as List<dynamic>? ?? [])
              .map((folderJson) => SubFolder.fromJson(folderJson))
              .toList(),
      events:
          (json['events'] as List<dynamic>? ?? [])
              .map((eventJson) => TripEvent.fromJson(eventJson))
              .toList(),
    );
  }
}

class Document {
  final String id;
  final String name;
  final String type;
  final int size;
  final String s3Key;
  final String uploadDate;

  Document({
    required this.id,
    required this.name,
    required this.type,
    required this.size,
    required this.s3Key,
    required this.uploadDate,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      size: json['size'] ?? 0,
      s3Key: json['s3_key'] ?? '',
      uploadDate: json['uploadDate'] ?? '',
    );
  }

  String get fileSize {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

class SubFolder {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final int documentCount;
  final List<Document> documents;

  SubFolder({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.documentCount,
    required this.documents,
  });

  factory SubFolder.fromJson(Map<String, dynamic> json) {
    // Handle both old format (List<String>) and new format (List<Document>)
    List<Document> documents = [];
    if (json['documents'] != null) {
      final docsList = json['documents'] as List<dynamic>;
      if (docsList.isNotEmpty) {
        // Check if first item is a string (old format) or object (new format)
        if (docsList.first is String) {
          // Old format: convert strings to Document objects
          documents =
              docsList
                  .map(
                    (docName) => Document(
                      id: _generateRandomId(),
                      name: docName.toString(),
                      type: _getFileTypeFromName(docName.toString()),
                      size: 0,
                      s3Key: '',
                      uploadDate: '',
                    ),
                  )
                  .toList();
        } else {
          // New format: parse as Document objects
          documents = docsList.map((doc) => Document.fromJson(doc)).toList();
        }
      }
    }

    return SubFolder(
      id: json['id'] ?? json['folderId'] ?? '',
      name: json['name'] ?? '',
      icon: TripEvent._getIconFromString(json['icon'] ?? 'folder'),
      color: TripEvent._getColorFromString(json['color'] ?? '#3B82F6'),
      documentCount: documents.length,
      documents: documents,
    );
  }

  static String _getFileTypeFromName(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return extension;
  }

  static String _generateRandomId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
