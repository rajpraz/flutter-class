import 'package:cloud_firestore/cloud_firestore.dart';

class Address {
  final String id;
  final String label;
  final String recipientName;
  final String phone;
  final String fullAddress;
  final bool isDefault;
  final DateTime? createdAt;

  const Address({
    this.id = '',
    required this.label,
    required this.recipientName,
    required this.phone,
    required this.fullAddress,
    this.isDefault = false,
    this.createdAt,
  });

  /// One-line summary used wherever a plain string address is needed (e.g.
  /// the `shippingAddress` sent to `createOrder`).
  String get formatted => '$recipientName, $fullAddress, $phone';

  factory Address.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? {};
    return Address(
      id: doc.id,
      label: (map['label'] as String?) ?? '',
      recipientName: (map['recipientName'] as String?) ?? '',
      phone: (map['phone'] as String?) ?? '',
      fullAddress: (map['fullAddress'] as String?) ?? '',
      isDefault: map['isDefault'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'recipientName': recipientName,
      'phone': phone,
      'fullAddress': fullAddress,
      'isDefault': isDefault,
      'createdAt': createdAt == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Address copyWith({String? label, String? recipientName, String? phone, String? fullAddress, bool? isDefault}) {
    return Address(
      id: id,
      label: label ?? this.label,
      recipientName: recipientName ?? this.recipientName,
      phone: phone ?? this.phone,
      fullAddress: fullAddress ?? this.fullAddress,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt,
    );
  }
}
