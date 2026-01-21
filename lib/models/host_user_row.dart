import 'package:cloud_firestore/cloud_firestore.dart';

class HostUserRow {
  final String userId;
  final String email;
  final String role;
  final bool isDisabled;
  final String? name;

  // ✅ NEW
  final String? address;
  final String? country;

  HostUserRow({
    required this.userId,
    required this.email,
    required this.role,
    required this.isDisabled,
    this.name,
    this.address,
    this.country,
  });

  factory HostUserRow.fromUserDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return HostUserRow(
      userId: (d['userId'] ?? doc.id).toString(),
      email: (d['email'] ?? '').toString(),
      role: (d['role'] ?? '').toString(),
      isDisabled: (d['isDisabled'] == true),
      name: (d['name'] ?? d['fullName'])?.toString(),

      // ✅ NEW
      address: (d['address'])?.toString(),
      country: (d['country'])?.toString(),
    );
  }
}
