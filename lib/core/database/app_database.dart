import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart';

part 'app_database.g.dart';

// --- Tables ---

class Messages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get senderId => text()();
  TextColumn get recipientId => text()();
  TextColumn get content => text()(); // Encrypted content (conceptually)
  DateTimeColumn get timestamp => dateTime()();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
}

class Contacts extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get username => text().nullable()(); // Optional alias
  TextColumn get publicKey => text()(); // Base64 encoded identity key
  
  @override
  Set<Column> get primaryKey => {id};
}

// --- Signal Protocol Tables ---

class Sessions extends Table {
  TextColumn get address => text()(); 
  IntColumn get deviceId => integer()();
  BlobColumn get record => blob()();
  
  @override
  Set<Column> get primaryKey => {address, deviceId};
}

class PreKeys extends Table {
  IntColumn get id => integer()(); // Key ID
  BlobColumn get record => blob()();
  
  @override
  Set<Column> get primaryKey => {id};
}

class SignedPreKeys extends Table {
  IntColumn get id => integer()(); // Key ID
  BlobColumn get record => blob()();
  
  @override
  Set<Column> get primaryKey => {id};
}

// --- Group Chat Tables ---

class Groups extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get createdBy => text()(); // User ID of creator
  TextColumn get avatarUrl => text().nullable()();
  
  @override
  Set<Column> get primaryKey => {id};
}

class GroupMembers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get groupId => text()();
  TextColumn get userId => text()();
  TextColumn get username => text().nullable()();
  DateTimeColumn get joinedAt => dateTime()();
  TextColumn get role => text().withDefault(const Constant('member'))(); // 'admin' or 'member'
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

class GroupMessages extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get groupId => text()();
  TextColumn get senderId => text()();
  TextColumn get senderName => text()();
  TextColumn get content => text()(); // Encrypted content
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get messageType => text().withDefault(const Constant('text'))(); // 'text', 'system', 'media'
  
  @override
  Set<Column> get primaryKey => {id};
}

// --- Database ---

@DriftDatabase(tables: [Messages, Contacts, Sessions, PreKeys, SignedPreKeys, Groups, GroupMembers, GroupMessages])
class AppDatabase extends _$AppDatabase {
  // Pass the executor to the super constructor
  AppDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 3; // Bumped for group chat tables

  // Factory initialization for encrypted database
  static Future<AppDatabase> initialize({required String password}) async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'encrypted.db'));

    final executor = NativeDatabase(
      file,
      setup: (rawDb) {
        // SQLCipher setup
        rawDb.execute("PRAGMA key = '$password';");
      },
    );

    return AppDatabase(executor);
  }

  // --- Queries ---

  /// Get all unique contacts we have chatted with, along with the latest message
  // valid SQL/Drift implementation for standard SQL:
  // We want to group by the 'other' person.
  Future<List<Contact>> getChatThreads() async {
     return select(contacts).get();
  }

  Stream<List<ChatThread>> watchChatThreads() {
    // Watch contacts. For each contact, fetching latest message might be N+1 custom query or a JOIN.
    // Let's generic JOIN:
    // SELECT c.*, m.content, m.timestamp FROM Contacts c 
    // LEFT JOIN Messages m ON m.id = (SELECT id FROM Messages WHERE senderId = c.id OR recipientId = c.id ORDER BY timestamp DESC LIMIT 1)
    
    // Using Dart validation for simplicity over complex Drift expressions for now:
    return select(contacts).watch().asyncMap((contactList) async {
       List<ChatThread> threads = [];
       for (var contact in contactList) {
         final lastMsg = await (select(messages)
            ..where((m) => m.senderId.equals(contact.id) | m.recipientId.equals(contact.id))
            ..orderBy([(t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)])
            ..limit(1))
            .getSingleOrNull();
            
         threads.add(ChatThread(contact, lastMsg));
       }
       // Sort by latest message
       threads.sort((a, b) {
          final tA = a.lastMessage?.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
          final tB = b.lastMessage?.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
          return tB.compareTo(tA);
       });
       return threads;
    });
  }
}

class ChatThread {
  final Contact contact;
  final Message? lastMessage;
  ChatThread(this.contact, this.lastMessage);
}
