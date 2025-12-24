import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../storage/secure_storage_service.dart';

class PanicService {
  final SecureStorageService _secureStorage;

  PanicService(this._secureStorage);

  /// TRIGGER THE PANIC BUTTON
  /// This deletes all encryption keys, the database file, and clears app secure storage.
  Future<void> triggerPanic() async {
    try {
      if (kDebugMode) {
        print("PANIC TRIGGERED! WIPING DATA...");
      }

      // 1. Wipe Keys
      await _secureStorage.deleteAll();

      // 2. Wipe Database File
      // We need to know where the DB is. Implementation must match AppDatabase.
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'encrypted.db'));
      
      if (await file.exists()) {
        await file.delete();
        if (kDebugMode) {
          print("Database file deleted.");
        }
      }

      // 3. Optional: Kill the app
      exit(0);
      
    } catch (e) {
      if (kDebugMode) {
        print("Panic failed partially: $e");
      }
      // Attempt to ensure exit even if cleanup failed
      exit(1); 
    }
  }
}
