import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:untitled3/features/addresses/domain/entities/address.dart';

/// `users/{uid}/addresses/{addressId}` — owner-only read/write per
/// firestore.rules. Not trust-sensitive the way orders/payments are (an
/// address is just where to ship, not what's charged), so plain client
/// Firestore writes — including the small "unset the old default" batch —
/// are appropriate here; no Cloud Function needed.
class AddressRemoteDataSource {
  static CollectionReference<Map<String, dynamic>> _items(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('addresses');

  Stream<List<Address>> streamAddresses(String uid) {
    return _items(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Address.fromDoc).toList());
  }

  Future<void> add(String uid, Address address) async {
    final collection = _items(uid);
    if (address.isDefault) {
      await _clearOtherDefaults(uid, keepId: null);
    }
    await collection.add(address.toMap());
  }

  Future<void> update(String uid, Address address) async {
    if (address.isDefault) {
      await _clearOtherDefaults(uid, keepId: address.id);
    }
    await _items(uid).doc(address.id).update(address.toMap());
  }

  Future<void> delete(String uid, String addressId) => _items(uid).doc(addressId).delete();

  Future<void> setDefault(String uid, String addressId) async {
    await _clearOtherDefaults(uid, keepId: addressId);
    await _items(uid).doc(addressId).update({'isDefault': true});
  }

  Future<void> _clearOtherDefaults(String uid, {required String? keepId}) async {
    final snap = await _items(uid).where('isDefault', isEqualTo: true).get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      if (doc.id == keepId) continue;
      batch.update(doc.reference, {'isDefault': false});
    }
    await batch.commit();
  }
}
