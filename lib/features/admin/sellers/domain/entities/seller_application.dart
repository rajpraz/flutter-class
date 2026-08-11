import 'package:cloud_firestore/cloud_firestore.dart';

class SellerApplication {
  final String uid;
  final String shopName;
  final String phone;
  final String reason;
  final String status; // pending | approved | rejected
  final DateTime? createdAt;

  const SellerApplication({
    required this.uid,
    required this.shopName,
    required this.phone,
    required this.reason,
    required this.status,
    this.createdAt,
  });

  factory SellerApplication.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? {};
    return SellerApplication(
      uid: doc.id,
      shopName: (map['shopName'] as String?) ?? '',
      phone: (map['phone'] as String?) ?? '',
      reason: (map['reason'] as String?) ?? '',
      status: (map['status'] as String?) ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
