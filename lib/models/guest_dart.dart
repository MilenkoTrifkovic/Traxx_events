import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class Guest_old {
  String id;
  String email;
  String name;
  int companions;
  DateTime? createdAt;
  bool invited;

  Guest_old({
    String? id,
    this.email = '',
    this.name = '',
    this.companions = 0,
    this.createdAt,
    this.invited = false,
  }) : id = id ?? Uuid().v4();

  void setCompanions(int count) {
    if (count >= 0) {
      companions = count;
    }
  }

  // Create Guest from Firestore document
  factory Guest_old.fromFirestore(Map<String, dynamic> data, String id) {
    return Guest_old(
      id: id,
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? '',
      companions: data['companions'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      invited: data['invited'] as bool? ?? false,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toFirestore({bool isUpdate = false}) {
    final data = {
      'id': id,
      'email': email,
      'name': name,
      'companions': companions,
      'createdAt': FieldValue.serverTimestamp(),
      'invited': invited,
    };
    if (!isUpdate) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    return data;
  }

  // Regular toJson for other purposes
  Map<String, dynamic> toJson() => toFirestore();

  // CopyWith method for immutability
  Guest_old copyWith({
    String? email,
    String? name,
    int? companions,
  }) {
    return Guest_old(
      id: id, // Keep the same ID
      email: email ?? this.email,
      name: name ?? this.name,
      companions: companions ?? this.companions,
      createdAt: createdAt,
      invited: invited,
    );
  }

  @override
  String toString() {
    return 'Guest(id: $id, email: $email, name: $name, companions: $companions), createdAt: $createdAt, invited: $invited';
  }
}
