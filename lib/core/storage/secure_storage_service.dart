import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Keys
  static const String _keyDbPassword = 'db_password';
  static const String _keyIdentityKeyPair = 'identity_key_pair';
  static const String _keyRegistrationId = 'registration_id';

  /// Save a string value securely
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// Read a string value securely
  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  /// Delete a specific key
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  /// Wipe all data (Panic Button)
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  // --- Helpers for specific keys ---

  Future<String?> getDatabasePassword() async {
    return await read(_keyDbPassword);
  }

  Future<void> setDatabasePassword(String password) async {
    await write(_keyDbPassword, password);
  }
}
