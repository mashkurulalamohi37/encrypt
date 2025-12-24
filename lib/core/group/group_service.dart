import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';

class GroupService {
  final AppDatabase _db;
  final String _currentUserId;
  final _uuid = const Uuid();

  GroupService(this._db, this._currentUserId);

  /// Create a new group with the given name and members
  Future<Group> createGroup({
    required String name,
    required List<String> memberIds,
    required Map<String, String> memberNames,
  }) async {
    final groupId = _uuid.v4();
    final now = DateTime.now();

    // Create the group
    final group = GroupsCompanion(
      id: Value(groupId),
      name: Value(name),
      createdAt: Value(now),
      createdBy: Value(_currentUserId),
    );

    await _db.into(_db.groups).insert(group);

    // Add creator as admin
    await _addMember(
      groupId: groupId,
      userId: _currentUserId,
      username: memberNames[_currentUserId] ?? 'You',
      role: 'admin',
      joinedAt: now,
    );

    // Add other members
    for (final memberId in memberIds) {
      if (memberId != _currentUserId) {
        await _addMember(
          groupId: groupId,
          userId: memberId,
          username: memberNames[memberId] ?? 'Unknown',
          role: 'member',
          joinedAt: now,
        );
      }
    }

    // Add system message
    await _addSystemMessage(
      groupId: groupId,
      content: 'Group created',
    );

    return await (_db.select(_db.groups)
          ..where((g) => g.id.equals(groupId)))
        .getSingle();
  }

  /// Add a member to an existing group
  Future<void> addMembers({
    required String groupId,
    required List<String> memberIds,
    required Map<String, String> memberNames,
  }) async {
    // Check if current user is admin
    final isAdmin = await _isUserAdmin(groupId, _currentUserId);
    if (!isAdmin) {
      throw Exception('Only admins can add members');
    }

    final now = DateTime.now();
    for (final memberId in memberIds) {
      // Check if already a member
      final existing = await (_db.select(_db.groupMembers)
            ..where((m) =>
                m.groupId.equals(groupId) &
                m.userId.equals(memberId) &
                m.isActive.equals(true)))
          .getSingleOrNull();

      if (existing == null) {
        await _addMember(
          groupId: groupId,
          userId: memberId,
          username: memberNames[memberId] ?? 'Unknown',
          role: 'member',
          joinedAt: now,
        );

        // Add system message
        await _addSystemMessage(
          groupId: groupId,
          content: '${memberNames[memberId] ?? 'Someone'} was added to the group',
        );
      }
    }
  }

  /// Remove a member from the group
  Future<void> removeMember({
    required String groupId,
    required String userId,
  }) async {
    // Check if current user is admin
    final isAdmin = await _isUserAdmin(groupId, _currentUserId);
    if (!isAdmin) {
      throw Exception('Only admins can remove members');
    }

    // Don't allow removing the last admin
    if (await _isUserAdmin(groupId, userId)) {
      final adminCount = await (_db.select(_db.groupMembers)
            ..where((m) =>
                m.groupId.equals(groupId) &
                m.role.equals('admin') &
                m.isActive.equals(true)))
          .get()
          .then((list) => list.length);

      if (adminCount <= 1) {
        throw Exception('Cannot remove the last admin');
      }
    }

    // Mark as inactive instead of deleting
    await (_db.update(_db.groupMembers)
          ..where((m) =>
              m.groupId.equals(groupId) &
              m.userId.equals(userId)))
        .write(const GroupMembersCompanion(
      isActive: Value(false),
    ));

    // Get member name for system message
    final member = await (_db.select(_db.groupMembers)
          ..where((m) =>
              m.groupId.equals(groupId) &
              m.userId.equals(userId)))
        .getSingle();

    // Add system message
    await _addSystemMessage(
      groupId: groupId,
      content: '${member.username ?? 'Someone'} was removed from the group',
    );
  }

  /// Leave a group
  Future<void> leaveGroup(String groupId) async {
    // Check if user is the last admin
    final isAdmin = await _isUserAdmin(groupId, _currentUserId);
    if (isAdmin) {
      final adminCount = await (_db.select(_db.groupMembers)
            ..where((m) =>
                m.groupId.equals(groupId) &
                m.role.equals('admin') &
                m.isActive.equals(true)))
          .get()
          .then((list) => list.length);

      if (adminCount <= 1) {
        throw Exception('Cannot leave as the last admin. Please assign another admin first.');
      }
    }

    // Mark as inactive
    await (_db.update(_db.groupMembers)
          ..where((m) =>
              m.groupId.equals(groupId) &
              m.userId.equals(_currentUserId)))
        .write(const GroupMembersCompanion(
      isActive: Value(false),
    ));

    // Get member name for system message
    final member = await (_db.select(_db.groupMembers)
          ..where((m) =>
              m.groupId.equals(groupId) &
              m.userId.equals(_currentUserId)))
        .getSingle();

    // Add system message
    await _addSystemMessage(
      groupId: groupId,
      content: '${member.username ?? 'Someone'} left the group',
    );
  }

  /// Update group name
  Future<void> updateGroupName({
    required String groupId,
    required String newName,
  }) async {
    // Check if current user is admin
    final isAdmin = await _isUserAdmin(groupId, _currentUserId);
    if (!isAdmin) {
      throw Exception('Only admins can update group name');
    }

    await (_db.update(_db.groups)
          ..where((g) => g.id.equals(groupId)))
        .write(GroupsCompanion(
      name: Value(newName),
    ));

    // Add system message
    await _addSystemMessage(
      groupId: groupId,
      content: 'Group name changed to "$newName"',
    );
  }

  /// Send a message to the group
  Future<void> sendGroupMessage({
    required String groupId,
    required String content,
    required String encryptedContent,
  }) async {
    // Check if user is a member
    final isMember = await _isUserMember(groupId, _currentUserId);
    if (!isMember) {
      throw Exception('You are not a member of this group');
    }

    final messageId = _uuid.v4();
    final member = await (_db.select(_db.groupMembers)
          ..where((m) =>
              m.groupId.equals(groupId) &
              m.userId.equals(_currentUserId) &
              m.isActive.equals(true)))
        .getSingle();

    final message = GroupMessagesCompanion(
      id: Value(messageId),
      groupId: Value(groupId),
      senderId: Value(_currentUserId),
      senderName: Value(member.username ?? 'Unknown'),
      content: Value(encryptedContent),
      timestamp: Value(DateTime.now()),
      messageType: const Value('text'),
    );

    await _db.into(_db.groupMessages).insert(message);
  }

  /// Watch messages for a group
  Stream<List<GroupMessage>> watchGroupMessages(String groupId) {
    return (_db.select(_db.groupMessages)
          ..where((m) => m.groupId.equals(groupId))
          ..orderBy([(m) => OrderingTerm(expression: m.timestamp)]))
        .watch();
  }

  /// Get group members
  Future<List<GroupMember>> getGroupMembers(String groupId) async {
    return await (_db.select(_db.groupMembers)
          ..where((m) =>
              m.groupId.equals(groupId) &
              m.isActive.equals(true)))
        .get();
  }

  /// Get all groups for current user
  Stream<List<GroupWithDetails>> watchUserGroups() {
    return (_db.select(_db.groupMembers)
          ..where((m) =>
              m.userId.equals(_currentUserId) &
              m.isActive.equals(true)))
        .watch()
        .asyncMap((members) async {
      List<GroupWithDetails> groups = [];
      for (var member in members) {
        final group = await (_db.select(_db.groups)
              ..where((g) => g.id.equals(member.groupId)))
            .getSingle();

        final lastMessage = await (_db.select(_db.groupMessages)
              ..where((m) => m.groupId.equals(group.id))
              ..orderBy([(m) => OrderingTerm(expression: m.timestamp, mode: OrderingMode.desc)])
              ..limit(1))
            .getSingleOrNull();

        final memberCount = await (_db.select(_db.groupMembers)
              ..where((m) =>
                  m.groupId.equals(group.id) &
                  m.isActive.equals(true)))
            .get()
            .then((list) => list.length);

        groups.add(GroupWithDetails(
          group: group,
          lastMessage: lastMessage,
          memberCount: memberCount,
        ));
      }

      // Sort by latest message
      groups.sort((a, b) {
        final tA = a.lastMessage?.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tB = b.lastMessage?.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tB.compareTo(tA);
      });

      return groups;
    });
  }

  /// Get group details
  Future<GroupWithMembers> getGroupDetails(String groupId) async {
    final group = await (_db.select(_db.groups)
          ..where((g) => g.id.equals(groupId)))
        .getSingle();

    final members = await getGroupMembers(groupId);

    return GroupWithMembers(group: group, members: members);
  }

  // --- Private Helper Methods ---

  Future<void> _addMember({
    required String groupId,
    required String userId,
    required String username,
    required String role,
    required DateTime joinedAt,
  }) async {
    final member = GroupMembersCompanion(
      groupId: Value(groupId),
      userId: Value(userId),
      username: Value(username),
      joinedAt: Value(joinedAt),
      role: Value(role),
      isActive: const Value(true),
    );

    await _db.into(_db.groupMembers).insert(member);
  }

  Future<void> _addSystemMessage({
    required String groupId,
    required String content,
  }) async {
    final messageId = _uuid.v4();
    final message = GroupMessagesCompanion(
      id: Value(messageId),
      groupId: Value(groupId),
      senderId: const Value('system'),
      senderName: const Value('System'),
      content: Value(content),
      timestamp: Value(DateTime.now()),
      messageType: const Value('system'),
    );

    await _db.into(_db.groupMessages).insert(message);
  }

  Future<bool> _isUserAdmin(String groupId, String userId) async {
    final member = await (_db.select(_db.groupMembers)
          ..where((m) =>
              m.groupId.equals(groupId) &
              m.userId.equals(userId) &
              m.isActive.equals(true)))
        .getSingleOrNull();

    return member?.role == 'admin';
  }

  Future<bool> _isUserMember(String groupId, String userId) async {
    final member = await (_db.select(_db.groupMembers)
          ..where((m) =>
              m.groupId.equals(groupId) &
              m.userId.equals(userId) &
              m.isActive.equals(true)))
        .getSingleOrNull();

    return member != null;
  }
}

// --- Helper Classes ---

class GroupWithDetails {
  final Group group;
  final GroupMessage? lastMessage;
  final int memberCount;

  GroupWithDetails({
    required this.group,
    this.lastMessage,
    required this.memberCount,
  });
}

class GroupWithMembers {
  final Group group;
  final List<GroupMember> members;

  GroupWithMembers({
    required this.group,
    required this.members,
  });
}
