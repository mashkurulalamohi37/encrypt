import 'dart:convert';
import 'dart:typed_data';

import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:drift/drift.dart'; // import for & operator
import '../database/app_database.dart';
import '../storage/secure_storage_service.dart';

class SignalStoreImpl implements SessionStore, PreKeyStore, SignedPreKeyStore, IdentityKeyStore {
  final AppDatabase _db;
  final SecureStorageService _secureStorage;

  SignalStoreImpl(this._db, this._secureStorage);

  // --- IdentityKeyStore ---

  @override
  Future<IdentityKeyPair> getIdentityKeyPair() async {
    final keyStr = await _secureStorage.read('identity_key_pair');
    if (keyStr == null) {
      throw Exception("Identity Key Pair not found! Initialize the app first.");
    }
    final bytes = base64Decode(keyStr);
    return IdentityKeyPair.fromSerialized(bytes); // Fixed fromBytes -> fromSerialized
  }

  // Missing implementation
  @override
  Future<IdentityKey?> getIdentity(SignalProtocolAddress address) async {
    final contact = await (_db.select(_db.contacts)..where((t) => t.id.equals(address.getName()))).getSingleOrNull();
    if (contact == null) return null;
    try {
      // Decode the stored key
      // Assuming we stored it as Base64 string from serialize()
      // Needs to handle if empty string
      if (contact.publicKey.isEmpty) return null;
      // Note: IdentityKey doesn't have fromString, need bytes.
      // But verify serialization format.
      // If we stored it as hex or base64. Let's assume hex or base64? 
      // In saveIdentity below we did: .toString(). This calls standard toString usually "[IdentityKey ...]" which is WRONG.
      // We must fix saveIdentity first to store serialize() (Uint8List).
      // For now, let's assume we fix saveIdentity to store base64.
       return IdentityKey.fromBytes(base64Decode(contact.publicKey), 0);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<int> getLocalRegistrationId() async {
    final regIdStr = await _secureStorage.read('registration_id');
    if (regIdStr == null) throw Exception("Registration ID not found!");
    return int.parse(regIdStr);
  }

  @override
  Future<bool> saveIdentity(SignalProtocolAddress address, IdentityKey? identityKey) async {
    if (identityKey == null) return false;
    
    // Store in Contacts/Trusted keys table
    await _db.into(_db.contacts).insertOnConflictUpdate(ContactsCompanion.insert(
      id: address.getName(), 
      publicKey: base64Encode(identityKey.serialize()), // FIXED: Serialize properly to base64
    ));
    return true;
  }

  @override
  Future<bool> isTrustedIdentity(SignalProtocolAddress address, IdentityKey? identityKey, Direction direction) async {
    final contact = await (_db.select(_db.contacts)..where((t) => t.id.equals(address.getName()))).getSingleOrNull();
    if (contact == null) {
      // TOFU (Trust On First Use): If no key exists, save it and trust.
      if (identityKey != null) {
        await saveIdentity(address, identityKey);
      }
      return true; 
    }
    // Compare stored key with incoming key
    return contact.publicKey == base64Encode(identityKey!.serialize());
  }

  // --- SessionStore ---
  
  @override
  Future<SessionRecord> loadSession(SignalProtocolAddress address) async {
    final record = await (_db.select(_db.sessions)
      ..where((t) => t.address.equals(address.getName()) & t.deviceId.equals(address.getDeviceId())))
      .getSingleOrNull();
    
    if (record != null) {
      return SessionRecord.fromSerialized(record.record);
    }
    return SessionRecord(); 
  }

  @override
  Future<void> storeSession(SignalProtocolAddress address, SessionRecord record) async {
    await _db.into(_db.sessions).insertOnConflictUpdate(SessionsCompanion.insert(
      address: address.getName(),
      deviceId: address.getDeviceId(),
      record: record.serialize(),
    ));
  }

  @override
  Future<bool> containsSession(SignalProtocolAddress address) async {
    final count = await (_db.select(_db.sessions)
      ..where((t) => t.address.equals(address.getName()) & t.deviceId.equals(address.getDeviceId())))
      .get().then((rows) => rows.length);
    return count > 0;
  }

  @override
  Future<void> deleteSession(SignalProtocolAddress address) async {
    await (_db.delete(_db.sessions)
      ..where((t) => t.address.equals(address.getName()) & t.deviceId.equals(address.getDeviceId())))
      .go();
  }

  @override
  Future<void> deleteAllSessions(String name) async {
     await (_db.delete(_db.sessions)..where((t) => t.address.equals(name))).go();
  }

  @override
  Future<List<int>> getSubDeviceSessions(String name) async {
    final rows = await (_db.select(_db.sessions)..where((t) => t.address.equals(name))).get();
    return rows.map((r) => r.deviceId).toList();
  }

  // --- PreKeyStore ---

  @override
  Future<PreKeyRecord> loadPreKey(int preKeyId) async {
    final row = await (_db.select(_db.preKeys)..where((t) => t.id.equals(preKeyId))).getSingleOrNull();
    if (row == null) throw InvalidKeyIdException("PreKey $preKeyId not found");
    return PreKeyRecord.fromBuffer(row.record);
  }

  @override
  Future<void> storePreKey(int preKeyId, PreKeyRecord record) async {
    await _db.into(_db.preKeys).insertOnConflictUpdate(PreKeysCompanion.insert(
      id: Value(preKeyId),
      record: record.serialize(),
    ));
  }

  @override
  Future<bool> containsPreKey(int preKeyId) async {
    final row = await (_db.select(_db.preKeys)..where((t) => t.id.equals(preKeyId))).getSingleOrNull();
    return row != null;
  }

  @override
  Future<void> removePreKey(int preKeyId) async {
    await (_db.delete(_db.preKeys)..where((t) => t.id.equals(preKeyId))).go();
  }

  // --- SignedPreKeyStore ---

  @override
  Future<SignedPreKeyRecord> loadSignedPreKey(int signedPreKeyId) async {
    final row = await (_db.select(_db.signedPreKeys)..where((t) => t.id.equals(signedPreKeyId))).getSingleOrNull();
    if (row == null) throw InvalidKeyIdException("SignedPreKey $signedPreKeyId not found");
    return SignedPreKeyRecord.fromSerialized(row.record); // FIXED: fromBuffer -> fromSerialized
  }

  @override
  Future<List<SignedPreKeyRecord>> loadSignedPreKeys() async {
     final rows = await _db.select(_db.signedPreKeys).get();
     return rows.map((r) => SignedPreKeyRecord.fromSerialized(r.record)).toList(); // FIXED: fromSerialized
  }

  @override
  Future<void> storeSignedPreKey(int signedPreKeyId, SignedPreKeyRecord record) async {
    await _db.into(_db.signedPreKeys).insertOnConflictUpdate(SignedPreKeysCompanion.insert(
      id: Value(signedPreKeyId),
      record: record.serialize(),
    ));
  }

  @override
  Future<bool> containsSignedPreKey(int signedPreKeyId) async {
     final row = await (_db.select(_db.signedPreKeys)..where((t) => t.id.equals(signedPreKeyId))).getSingleOrNull();
     return row != null;
  }

  @override
  Future<void> removeSignedPreKey(int signedPreKeyId) async {
     await (_db.delete(_db.signedPreKeys)..where((t) => t.id.equals(signedPreKeyId))).go();
  }
}
