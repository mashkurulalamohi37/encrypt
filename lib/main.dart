import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'core/database/app_database.dart';
import 'core/encryption/encryption_service.dart';
import 'core/storage/secure_storage_service.dart';
import 'core/security/panic_service.dart';
import 'core/network/transport_service.dart';
import 'ui/screens/chat_list_screen.dart';
import 'ui/screens/biometric_lock_screen.dart';
import 'ui/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // 1. Initialize Secure Storage
    final secureStorage = SecureStorageService();
    
    // 2. Database Encryption Key Logic
    String? dbAuth = await secureStorage.getDatabasePassword();
    if (dbAuth == null) {
      dbAuth = const Uuid().v4(); // Generate a random key
      await secureStorage.setDatabasePassword(dbAuth);
    }

    // 3. Initialize Database
    final db = await AppDatabase.initialize(password: dbAuth);
    
    // 4. Initialize Network
    final transportService = TransportService();

    // 5. Initialize Encryption Service (Signal Protocol)
    final encryptionService = EncryptionService(db, secureStorage, transportService);
    await encryptionService.initialize();

    // 6. Initialize Panic Service
    final panicService = PanicService(secureStorage);

    runApp(
      MultiProvider(
        providers: [
          Provider<AppDatabase>.value(value: db),
          Provider<SecureStorageService>.value(value: secureStorage),
          Provider<EncryptionService>.value(value: encryptionService),
          Provider<PanicService>.value(value: panicService),
          Provider<TransportService>.value(value: transportService),
        ],
        child: const ZeroCostApp(),
      ),
    );
  } catch (e, stackTrace) {
    print('INITIALIZATION ERROR: $e');
    print('Stack trace: $stackTrace');
    
    // Show error screen instead of crashing
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Initialization Error', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('$e', textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

class ZeroCostApp extends StatelessWidget {
  const ZeroCostApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Encrypted Messenger',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const BiometricLockScreen(
        child: ChatListScreen(),
      ),
    );
  }
}
