
import 'package:flutter/material.dart';


class Client {
  final String id;
  String name;
  String email;
  String phone;

  Client({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });

  Client copyWith({String? id, String? name, String? email, String? phone}) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'email': email, 'phone': phone};
  }

  factory Client.fromJson(Map<String, dynamic> json) {
    String clientId = 'id_inconnu';

    
    if (json['clientId'] != null) {
      clientId = json['clientId'].toString();
    } else if (json['id'] != null) {
      clientId = json['id'].toString();
    } else if (json['PK'] != null &&
        json['PK'].toString().startsWith('CLIENT#')) {
      clientId =
          json['PK'].toString().split('#').length > 1
              ? json['PK'].toString().split('#')[1]
              : 'id_inconnu';
    } else if (json['SK'] != null && json['SK'].toString().contains('#')) {
      final parts = json['SK'].toString().split('#');
      clientId = parts.length > 1 ? parts[1] : 'id_inconnu';
    }

    return Client(
      id: clientId,
      name: json['clientName'] ?? json['name'] ?? 'Nom non disponible',
      email: json['clientEmail'] ?? json['email'] ?? 'Email non disponible',
      phone: json['clientPhone'] ?? json['phone'] ?? 'Téléphone non disponible',
    );
  }
}


class Document {
  final String id;
  String name;
  final String type;
  final String path;
  final DateTime uploadDate;
  final String size;

  Document({
    required this.id,
    required this.name,
    required this.type,
    required this.path,
    required this.uploadDate,
    required this.size,
  });

  Document copyWith({
    String? id,
    String? name,
    String? type,
    String? path,
    DateTime? uploadDate,
    String? size,
  }) {
    return Document(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      path: path ?? this.path,
      uploadDate: uploadDate ?? this.uploadDate,
      size: size ?? this.size,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'path': path,
      'uploadDate': uploadDate.toIso8601String(),
      'size': size,
    };
  }

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] ?? 'id_inconnu',
      name: json['name'] ?? 'Nom inconnu',
      type: json['type'] ?? 'inconnu',
      path: json['s3_key'] ?? '',
      uploadDate: DateTime.tryParse(json['uploadDate'] ?? '') ?? DateTime.now(),
      size: json['size']?.toString() ?? '0 B',
    );
  }
}


class SubFolder {
  final String id;
  String name;
  IconData icon;
  Color color;
  final List<Document> documents;

  int get documentCount => documents.length;

  SubFolder({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.documents,
  });

  SubFolder copyWith({
    String? id,
    String? name,
    IconData? icon,
    Color? color,
    List<Document>? documents,
  }) {
    return SubFolder(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      documents: documents ?? List.from(this.documents),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon.codePoint,
      'color': color.value,
      'documents': documents.map((doc) => doc.toJson()).toList(),
    };
  }

  factory SubFolder.fromJson(Map<String, dynamic> json) {
    var documentsList = <Document>[];

    if (json['documents'] != null && json['documents'] is List) {
      try {
        documentsList =
            (json['documents'] as List<dynamic>)
                .map(
                  (docJson) =>
                      Document.fromJson(docJson as Map<String, dynamic>),
                )
                .toList();
      } catch (e) {
        print('Erreur lors du parsing des documents: $e');
        documentsList = [];
      }
    }

    IconData icon = _mapIconFromString(json['icon'] ?? 'folder');
    Color color = _mapColorFromString(json['color'] ?? 'blue');

    return SubFolder(
      id: json['id'] ?? 'id_inconnu',
      name: json['name'] ?? 'Dossier sans nom',
      icon: icon,
      color: color,
      documents: documentsList,
    );
  }

  static IconData _mapIconFromString(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'flight':
        return Icons.flight;
      case 'hotel':
        return Icons.hotel;
      case 'directions_car':
        return Icons.directions_car;
      case 'tour':
        return Icons.tour;
      case 'restaurant':
        return Icons.restaurant;
      case 'description':
        return Icons.description;
      default:
        return Icons.folder;
    }
  }

  static Color _mapColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'red':
        return Colors.red;
      case 'teal':
        return Colors.teal;
      default:
        return Colors.blue;
    }
  }
}


class TripDay {
  final String id;
  String dayTitle;
  String date;
  String description;
  final List<SubFolder> subFolders;
  final List<TripEvent> events;

  TripDay({
    required this.id,
    required this.dayTitle,
    required this.date,
    this.description = '',
    required this.subFolders,
    this.events = const [],
  });

  TripDay copyWith({
    String? id,
    String? dayTitle,
    String? date,
    String? description,
    List<SubFolder>? subFolders,
    List<TripEvent>? events,
  }) {
    return TripDay(
      id: id ?? this.id,
      dayTitle: dayTitle ?? this.dayTitle,
      date: date ?? this.date,
      description: description ?? this.description,
      subFolders: subFolders ?? List.from(this.subFolders),
      events: events ?? List.from(this.events),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dayTitle': dayTitle,
      'date': date,
      'description': description,
      'subFolders': subFolders.map((folder) => folder.toJson()).toList(),
      'events': events.map((event) => event.toJson()).toList(),
    };
  }

  factory TripDay.fromJson(Map<String, dynamic> json) {
    var subFoldersList = <SubFolder>[];

    if (json['subFolders'] != null && json['subFolders'] is List) {
      try {
        subFoldersList =
            (json['subFolders'] as List<dynamic>)
                .map(
                  (folderJson) =>
                      SubFolder.fromJson(folderJson as Map<String, dynamic>),
                )
                .toList();
      } catch (e) {
        print('Erreur lors du parsing des sous-dossiers: $e');
        subFoldersList = [];
      }
    }

    return TripDay(
      id: json['id'] ?? 'id_inconnu',
      dayTitle: json['dayTitle'] ?? 'Jour sans titre',
      date: json['date'] ?? 'Date inconnue',
      description: json['description'] ?? '',
      subFolders: subFoldersList,
      events: [],
    );
  }
}


class Trip {
  final String id;
  final Client client;
  String tripDestination;
  final DateTime startDate;
  final DateTime endDate;
  final List<TripDay> days;
  String status;

  Trip({
    required this.id,
    required this.client,
    required this.tripDestination,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.status,
  });

  int get duration => endDate.difference(startDate).inDays + 1;

  int get totalDocuments {
    return days.fold<int>(
      0,
      (sum, day) =>
          sum +
          day.subFolders.fold<int>(
            0,
            (subSum, folder) => subSum + folder.documents.length,
          ),
    );
  }

  int get totalSubFolders {
    return days.fold<int>(0, (sum, day) => sum + day.subFolders.length);
  }

  Trip copyWith({
    String? id,
    Client? client,
    String? tripDestination,
    DateTime? startDate,
    DateTime? endDate,
    List<TripDay>? days,
    String? status,
  }) {
    return Trip(
      id: id ?? this.id, 
      client: client ?? this.client,
      tripDestination: tripDestination ?? this.tripDestination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      days: days ?? List.from(this.days),
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client': client.toJson(),
      'tripDestination': tripDestination,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status,
      'days': days.map((day) => day.toJson()).toList(),
    };
  }

  factory Trip.fromJson(Map<String, dynamic> json, {required Client client}) {
    print('=== TRIP.FROM_JSON ===');
    print('Input JSON: $json');

    
    String tripId = 'id_inconnu';
    if (json['SK'] != null && json['SK'].toString().startsWith('TRIP#')) {
      final parts = json['SK'].toString().split('#');
      tripId = parts.length > 1 ? parts[1] : 'id_inconnu';
      print('Found ID in SK: $tripId');
    } else if (json['id'] != null) {
      tripId = json['id'].toString();
      print('Found ID in json[id]: $tripId');
    } else if (json['PK'] != null &&
        json['PK'].toString().startsWith('TRIP#')) {
      final parts = json['PK'].toString().split('#');
      tripId = parts.length > 1 ? parts[1] : 'id_inconnu';
      print('Found ID in PK: $tripId');
    }

    print('Final Trip ID: $tripId');

    
    var daysList = <TripDay>[];
    if (json['days'] != null && json['days'] is List) {
      try {
        daysList =
            (json['days'] as List<dynamic>)
                .map(
                  (dayJson) =>
                      TripDay.fromJson(dayJson as Map<String, dynamic>),
                )
                .toList();
      } catch (e) {
        print('Erreur lors du parsing des jours: $e');
        daysList = [];
      }
    }

    final trip = Trip(
      id: tripId,
      client: client,
      tripDestination: json['tripDestination'] ?? 'Destination inconnue',
      startDate: DateTime.tryParse(json['startDate'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['endDate'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? 'Statut inconnu',
      days: daysList,
    );

    print('Created Trip: ID=${trip.id}, Destination=${trip.tripDestination}');
    return trip;
  }
}


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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'icon': icon.codePoint,
      'color': color.value,
    };
  }

  factory TripEvent.fromJson(Map<String, dynamic> json) {
    return TripEvent(
      id: json['id'] ?? 'id_inconnu',
      title: json['title'] ?? 'Événement sans titre',
      location: json['location'] ?? 'Lieu inconnu',
      icon: IconData(
        json['icon'] ?? Icons.event.codePoint,
        fontFamily: 'MaterialIcons',
      ),
      color: Color(json['color'] ?? Colors.blue.value),
    );
  }
}
