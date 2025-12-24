# Group Chat System Implementation Plan

## Overview
Add group chat functionality to the encrypted messenger app, allowing multiple users to communicate in encrypted group conversations.

## Architecture

### 1. Database Schema Changes

#### New Tables

**groups**
- `id` (TEXT, PRIMARY KEY) - Unique group identifier
- `name` (TEXT) - Group name
- `created_at` (DATETIME)
- `created_by` (TEXT) - Creator's user ID
- `avatar_url` (TEXT, NULLABLE) - Group avatar

**group_members**
- `id` (INTEGER, PRIMARY KEY, AUTOINCREMENT)
- `group_id` (TEXT, FOREIGN KEY -> groups.id)
- `user_id` (TEXT) - Member's user ID
- `username` (TEXT, NULLABLE) - Member's display name
- `joined_at` (DATETIME)
- `role` (TEXT) - 'admin' or 'member'
- `is_active` (BOOLEAN) - Whether member is still in group

**group_messages**
- `id` (TEXT, PRIMARY KEY)
- `group_id` (TEXT, FOREIGN KEY -> groups.id)
- `sender_id` (TEXT) - Who sent the message
- `sender_name` (TEXT) - Display name of sender
- `content` (TEXT) - Encrypted message content
- `timestamp` (DATETIME)
- `message_type` (TEXT) - 'text', 'system', 'media'

#### Modified Tables

**chat_threads** - Add column:
- `is_group` (BOOLEAN, DEFAULT false)
- `group_id` (TEXT, NULLABLE, FOREIGN KEY -> groups.id)

### 2. Encryption Strategy

#### Sender Keys Protocol (Signal Protocol)
- Each group has a shared encryption key
- When a user sends a message:
  1. Encrypt message with group's sender key
  2. All members can decrypt using the same key
  3. Key rotation when members join/leave

#### Key Distribution
- When creating a group:
  1. Generate a group encryption key
  2. Encrypt the key for each member using their public key
  3. Store encrypted keys in secure storage

### 3. Core Services

#### GroupService
```dart
class GroupService {
  // Group management
  Future<Group> createGroup(String name, List<String> memberIds);
  Future<void> addMembers(String groupId, List<String> memberIds);
  Future<void> removeMember(String groupId, String userId);
  Future<void> leaveGroup(String groupId);
  Future<void> updateGroupName(String groupId, String newName);
  
  // Messaging
  Future<void> sendGroupMessage(String groupId, String content);
  Stream<List<GroupMessage>> watchGroupMessages(String groupId);
  
  // Members
  Future<List<GroupMember>> getGroupMembers(String groupId);
  Future<bool> isUserInGroup(String groupId, String userId);
}
```

#### GroupEncryptionService
```dart
class GroupEncryptionService {
  Future<String> encryptGroupMessage(String groupId, String plaintext);
  Future<String> decryptGroupMessage(String groupId, String ciphertext);
  Future<void> rotateGroupKey(String groupId);
  Future<void> distributeKeyToMember(String groupId, String memberId);
}
```

### 4. UI Components

#### New Screens

**GroupListScreen**
- Shows all groups user is part of
- Integrated into ChatListScreen with tabs (Direct | Groups)

**GroupChatScreen**
- Similar to ChatScreen but shows sender names
- Group info header (name, member count)
- Message bubbles show sender name

**CreateGroupScreen**
- Group name input
- Member selection (multi-select from contacts)
- Create button

**GroupInfoScreen**
- Group details (name, created date)
- Member list with roles
- Add members button
- Leave group button
- Admin actions (remove members, delete group)

**AddGroupMembersScreen**
- Multi-select contact list
- Add selected members to group

### 5. Features

#### Phase 1: Basic Group Chat
- [x] Create group with name
- [x] Add multiple members
- [x] Send/receive messages in group
- [x] View group messages
- [x] See sender name on each message

#### Phase 2: Group Management
- [x] View group members
- [x] Add new members to existing group
- [x] Remove members (admin only)
- [x] Leave group
- [x] Rename group (admin only)

#### Phase 3: Advanced Features
- [ ] Group avatars
- [ ] Admin/member roles
- [ ] Typing indicators for groups
- [ ] Read receipts (who read the message)
- [ ] Message reactions
- [ ] Reply to specific messages
- [ ] Media sharing in groups
- [ ] Group notifications settings

### 6. Implementation Steps

#### Step 1: Database Schema (30 min)
1. Create migration for new tables
2. Update AppDatabase with new tables
3. Create Drift entities for groups, members, messages

#### Step 2: Core Services (1 hour)
1. Implement GroupService
2. Implement GroupEncryptionService
3. Add group message handling to EncryptionService

#### Step 3: UI - Create Group (45 min)
1. Create CreateGroupScreen
2. Add member selection UI
3. Wire up to GroupService

#### Step 4: UI - Group Chat (1 hour)
1. Create GroupChatScreen
2. Adapt message bubbles to show sender names
3. Add group header with info
4. Connect to GroupService for messages

#### Step 5: UI - Group List (30 min)
1. Add groups tab to ChatListScreen
2. Show group list items
3. Navigate to GroupChatScreen

#### Step 6: UI - Group Info (45 min)
1. Create GroupInfoScreen
2. Show member list
3. Add member management actions

#### Step 7: Testing & Polish (30 min)
1. Test group creation
2. Test messaging
3. Test member management
4. Handle edge cases

**Total Estimated Time: 5 hours**

### 7. Security Considerations

1. **End-to-End Encryption**: All group messages encrypted
2. **Key Rotation**: Rotate keys when members join/leave
3. **Forward Secrecy**: Old messages can't be decrypted after key rotation
4. **Member Verification**: Verify all members before adding
5. **Admin Controls**: Only admins can modify group settings

### 8. Database Queries

```dart
// Get all groups for a user
Stream<List<Group>> watchUserGroups(String userId);

// Get group with members
Future<GroupWithMembers> getGroupDetails(String groupId);

// Get recent group messages
Stream<List<GroupMessage>> watchGroupMessages(String groupId, {int limit = 50});

// Check if user is admin
Future<bool> isGroupAdmin(String groupId, String userId);
```

### 9. Message Format

**Group Message Structure:**
```json
{
  "id": "msg_uuid",
  "group_id": "group_uuid",
  "sender_id": "user_id",
  "sender_name": "John Doe",
  "content": "encrypted_content",
  "timestamp": "2024-12-24T10:30:00Z",
  "type": "text"
}
```

**System Messages:**
```json
{
  "type": "system",
  "content": "John Doe added Alice to the group"
}
```

### 10. UI/UX Design

#### Group Chat Bubble Design
```
┌─────────────────────────────┐
│ Alice                       │ ← Sender name (if not you)
│ ┌─────────────────────────┐ │
│ │ Hey everyone! 👋        │ │ ← Message content
│ └─────────────────────────┘ │
│                      10:30  │ ← Timestamp
└─────────────────────────────┘
```

#### Group List Item
```
┌─────────────────────────────────────┐
│ [👥] Project Team                   │
│      Alice: Thanks for the update   │
│                              10:30  │
│                                  3  │ ← Unread count
└─────────────────────────────────────┘
```

### 11. Network Protocol

**Create Group:**
```
POST /groups/create
{
  "name": "Group Name",
  "members": ["user1_id", "user2_id"],
  "encryption_keys": {
    "user1_id": "encrypted_key_1",
    "user2_id": "encrypted_key_2"
  }
}
```

**Send Group Message:**
```
POST /groups/{group_id}/messages
{
  "content": "encrypted_message",
  "sender_id": "user_id"
}
```

### 12. Notifications

- **New Group Message**: "Alice in Project Team: Hey everyone!"
- **Added to Group**: "You were added to Project Team"
- **Member Joined**: "Bob joined the group"
- **Member Left**: "Alice left the group"

### 13. Error Handling

- Group not found
- User not a member
- Insufficient permissions (not admin)
- Encryption key not available
- Member already in group
- Cannot remove last admin

### 14. Performance Optimizations

1. **Pagination**: Load messages in batches
2. **Caching**: Cache group member list
3. **Lazy Loading**: Load group details on demand
4. **Indexing**: Index group_id and sender_id in messages

### 15. Future Enhancements

- Voice/video group calls
- File sharing in groups
- Group polls
- Pinned messages
- Group search
- Archive groups
- Mute notifications per group
- Custom group themes

---

## Ready to Implement?

This is a comprehensive plan. We can start with **Phase 1: Basic Group Chat** which includes:
1. Database schema
2. Core services
3. Create group UI
4. Group chat UI
5. Basic messaging

Would you like me to start implementing this? We can do it step by step!
