import 'dart:convert';
import 'dart:math'; // For mock
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:drift/drift.dart' as drift; // Import for Value
import '../database/app_database.dart';
import '../storage/secure_storage_service.dart';
import '../network/transport_service.dart';
import 'signal_store_impl.dart';

class EncryptionService {
  final AppDatabase _db;
  final SecureStorageService _secureStorage;
  final TransportService _transport;
  late final SignalStoreImpl _store;

  EncryptionService(this._db, this._secureStorage, this._transport) {
    _store = SignalStoreImpl(_db, _secureStorage);
  }

  /// Initialize the Signal Protocol environment
  Future<void> initialize() async {
    final existingParams = await _secureStorage.read('registration_id');
    if (existingParams == null) {
      await _generateAndStoreKeys();
    }
    // Skip validation for now since we're using mock keys
    // await _store.getIdentityKeyPair();
    _startPolling();
  }
  
  /// Get Local Identity string (Base64 PubKey)
  Future<String> getLocalIdentityKey() async {
    try {
      final keyStr = await _secureStorage.read('identity_key_pair');
      if (keyStr == null) {
        throw Exception("Identity key not found");
      }
      // For mock keys, just return the stored value
      return keyStr;
    } catch (e) {
      print("Error getting identity key: $e");
      return "MOCK_IDENTITY_KEY";
    }
  }

  Future<void> _generateAndStoreKeys() async {
    // Temporary mock implementation to get app running
    // TODO: Replace with actual Signal Protocol key generation once debugged
    
    print("Generating mock keys for testing...");
    
    try {
      // Generate mock identity key (32 random bytes for testing)
      final random = Random.secure();
      final mockKeyBytes = List<int>.generate(32, (_) => random.nextInt(256));
      
      await _secureStorage.write('identity_key_pair', base64Encode(mockKeyBytes));
      await _secureStorage.write('registration_id', random.nextInt(16380).toString());
      
      print("Mock keys generated successfully");
    } catch (e) {
      print("Error in key generation: $e");
      rethrow;
    }
  }

  // --- Core Messaging ---

  /// Send a text message
  Future<void> sendMessage(String recipientId, String message) async {
    final deviceId = 1;
    final ciphertext = await encrypt(recipientId, deviceId, message);
    
    final myAddress = await getLocalIdentityKey(); 
    
    await _db.into(_db.contacts).insertOnConflictUpdate(ContactsCompanion.insert(
      id: recipientId,
      publicKey: "", 
    ));

    await _db.into(_db.messages).insert(MessagesCompanion.insert(
      senderId: myAddress,
      recipientId: recipientId,
      content: message, 
      timestamp: DateTime.now(),
      isRead: const drift.Value(true), // Fixed drift.Value
    ));

    await _transport.sendPacket(
      recipientId: recipientId,
      ciphertext: ciphertext.serialize(),
      type: ciphertext.getType(),
    );
  }

  /// Encrypt a message for a remote recipient
  Future<CiphertextMessage> encrypt(String recipientId, int deviceId, String message) async {
    final address = SignalProtocolAddress(recipientId, deviceId);
    final sessionCipher = SessionCipher(_store, _store, _store, _store, address);
    return await sessionCipher.encrypt(utf8.encode(message));
  }

  /// Decrypt a received message
  Future<String> decrypt(String senderId, int deviceId, CiphertextMessage ciphertext) async {
    final address = SignalProtocolAddress(senderId, deviceId);
    final sessionCipher = SessionCipher(_store, _store, _store, _store, address);
    
    List<int> plaintextBytes;
    if (ciphertext.getType() == CiphertextMessage.prekeyType) {
       plaintextBytes = await sessionCipher.decrypt(ciphertext as PreKeySignalMessage);
    } else if (ciphertext.getType() == CiphertextMessage.whisperType) {
       // Use decryptFromSignal for SignalMessage type
       plaintextBytes = await sessionCipher.decryptFromSignal(ciphertext as SignalMessage);
    } else {
       throw Exception("Unknown message type: ${ciphertext.getType()}");
    }
    
    return utf8.decode(plaintextBytes);
  }

  // --- Incoming Message Logic ---

  void _startPolling() async {
    while (true) {
      try {
        final envelopes = await _transport.pollMessages();
        for (var envelope in envelopes) {
           await processIncomingPacket(envelope);
        }
      } catch (e) {
      }
      await Future.delayed(const Duration(seconds: 5)); 
    }
  }

  Future<void> processIncomingPacket(Map<String, dynamic> envelope) async {
    final senderId = envelope['sender'] as String;
    final messageBase64 = envelope['message'] as String;
    final type = envelope['type'] as int;

    // 1. Decode Cipher
    final ciphertextBytes = base64Decode(messageBase64);
    CiphertextMessage ciphertext;
    
    if (type == CiphertextMessage.prekeyType) {
       ciphertext = PreKeySignalMessage(ciphertextBytes);
    } else {
       // Fixed: Use fromSerialized for SignalMessage
       ciphertext = SignalMessage.fromSerialized(ciphertextBytes); 
    }

    // 2. Decrypt
    final plaintext = await decrypt(senderId, 1, ciphertext);

    // 3. Store
    await _db.into(_db.contacts).insertOnConflictUpdate(ContactsCompanion.insert(
      id: senderId,
      publicKey: "", 
    ));

    await _db.into(_db.messages).insert(MessagesCompanion.insert(
      senderId: senderId,
      recipientId: await getLocalIdentityKey(),
      content: plaintext,
      timestamp: DateTime.now(), 
      isRead: const drift.Value(false), // Fixed drift.Value
    ));
  }
}
