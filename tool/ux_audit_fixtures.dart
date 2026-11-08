// Synthetic, in-memory inputs for reproducible UX checks. No live transport.
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/core/preferences_storage.dart';
import 'package:vnlfsocialapp/src/core/session_storage_contract.dart';
import 'package:vnlfsocialapp/src/data/fixture_repositories.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/domain/repositories.dart';
import 'package:vnlfsocialapp/src/features/composer/data/composer_recovery.dart';
import 'package:vnlfsocialapp/src/features/composer/domain/composer_draft.dart';
import 'package:vnlfsocialapp/src/features/composer/domain/composer_poll.dart';
import 'package:vnlfsocialapp/src/features/voice/domain/voice_models.dart';
import 'package:vnlfsocialapp/src/features/voice/domain/voice_repository.dart';
import 'package:vnlfsocialapp/src/features/voice/domain/voice_room_session.dart';
import 'package:vnlfsocialapp/src/features/voice/presentation/voice_providers.dart';

const auditOwner = Session(
  userId: 'audit-owner',
  username: 'kiemtra',
  displayName: 'Thành viên kiểm tra',
  role: 'MEMBER',
);
const auditFeedbackId = '11111111-1111-4111-8111-111111111111';

List<Override> auditOverrides({bool populatedComposer = false}) {
  final sessionStorage = AuditMemoryStorage();
  if (populatedComposer) {
    ComposerRecovery(sessionStorage).write(
      auditOwner.userId,
      RecoveredComposition(
        ComposerDraft(
          id: '',
          version: 0,
          document: const {
            'type': 'doc',
            'content': [
              {
                'type': 'paragraph',
                'content': [
                  {
                    'type': 'text',
                    'text': 'Chia sẻ cấu hình Linux với cộng đồng. Tiếng Việt: ặ ữ ờ ẫ ệ.',
                  },
                ],
              },
            ],
          },
          pollDraft: ComposerPollDraft('Bạn đang dùng bản phân phối nào?', [
            'Arch Linux',
            'Debian',
          ]),
        ),
        false,
        null,
      ),
    );
  }
  return [
    ioTransportProvider.overrideWithValue(null),
    preferencesStorageProvider.overrideWithValue(AuditMemoryStorage()),
    sessionStorageProvider.overrideWithValue(sessionStorage),
    authRepositoryProvider.overrideWithValue(const AuditAuthRepository()),
    voiceRepositoryProvider.overrideWithValue(const AuditVoiceRepository()),
    voiceRoomSessionFactoryProvider.overrideWithValue(
      () => AuditVoiceSession(),
    ),
    sessionStateProvider.overrideWith((ref) => auditOwner),
    sessionProvider.overrideWithValue(const AsyncData(auditOwner)),
    apiClientProvider.overrideWith((ref) {
      final client = ApiClient(
        transport: auditTransport,
        hostKey: Object(),
        throttleInterval: Duration.zero,
      );
      ref.onDispose(client.invalidateSession);
      return client;
    }),
  ];
}

class AuditAuthRepository implements AuthRepository {
  const AuditAuthRepository();
  @override
  Future<Session?> currentSession() async => auditOwner;
  @override
  Future<Session> login(String login, String password) async =>
      throw StateError('Audit is read-only');
  @override
  Future<Session> register(
    String email,
    String username,
    String password,
  ) async => throw StateError('Audit is read-only');
  @override
  Future<void> logout() async => throw StateError('Audit is read-only');
}

const auditVoiceRoom = VoiceRoom(
  id: 'audit-room',
  name: 'Phòng Linux Việt Nam',
  status: 'ACTIVE',
  description: 'Không gian trao đổi cấu hình Linux',
  participantCount: 2,
);

class AuditVoiceRepository implements VoiceRepository {
  const AuditVoiceRepository();
  @override
  Future<List<VoiceRoom>> getRooms() async => [auditVoiceRoom];
  @override
  Future<VoiceConnection> join(String roomId) async =>
      const VoiceConnection(serverUrl: '', token: '');
  @override
  Future<void> leave(String roomId) async {}
}

class AuditVoiceSession implements VoiceRoomSession {
  @override
  Stream<VoiceRoomSnapshot> get changes => const Stream.empty();
  @override
  VoiceRoomSnapshot get snapshot => const VoiceRoomSnapshot(
    phase: VoicePhase.connected,
    participants: [
      VoiceMember(
        id: 'audit-peer',
        name: 'Bạn đọc Linux',
        username: 'banlinux',
        speaking: true,
        muted: false,
      ),
      VoiceMember(
        id: 'audit-owner',
        name: 'Thành viên kiểm tra',
        username: 'kiemtra',
        local: true,
      ),
    ],
  );
  @override
  Future<void> connect(VoiceConnection connection) async {}
  @override
  Future<void> setMicrophoneEnabled(bool enabled) async {}
  @override
  Future<void> setPlaybackEnabled(bool enabled) async {}
  @override
  Future<void> close() async {}
}

class AuditMemoryStorage implements PreferencesStorage, SessionStorage {
  final _values = <String, String>{};
  @override
  Future<String?> read(String key) async => _values[key];
  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }
}

const _peer = {
  'id': 'audit-peer',
  'username': 'banlinux',
  'displayName': 'Bạn đọc Linux',
  'presence': 'ONLINE',
};
const _conversation = {
  'id': 'audit-dm',
  'status': 'ACTIVE',
  'viewerState': 'ACTIVE',
  'canSend': true,
  'unreadCount': 2,
  'peer': _peer,
  'lastMessage': 'Tiếng Việt: ặ ữ ờ ẫ ệ',
  'firstUnreadMessageId': 'audit-message',
  'peerLastReadMessageId': 'audit-own-message',
};
const _ticket = {
  'id': auditFeedbackId,
  'reference': 'VNLF-AUDIT001',
  'kind': 'FEEDBACK',
  'status': 'OPEN',
  'detail': 'Kiểm tra cách hiển thị giao diện và dấu tiếng Việt: ặ ữ ờ ẫ ệ.',
  'pagePath': '/',
  'attachmentCount': 0,
  'messageCount': 1,
  'createdAt': '2026-11-08T08:00:00Z',
  'updatedAt': '2026-11-08T08:00:00Z',
  'staffReplied': true,
};

Future<ApiResponse> auditTransport(ApiRequest request) async {
  ApiResponse json(Object value) =>
      ApiResponse(statusCode: 200, body: jsonEncode(value));
  // Reading a timeline acknowledges it locally. All other writes are rejected.
  if (request.method != 'GET') {
    if (request.path.endsWith('/read')) {
      return json({'ok': true, 'lastReadMessageId': 'audit-message'});
    }
    return ApiResponse(statusCode: 405, body: '{"code":"AUDIT_READ_ONLY"}');
  }
  switch (request.path) {
    case '/api/v1/projects':
      final response = await fixtureTransport(request);
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      for (final project in data['items'] as List) {
        project['type'] = 'TOOL';
        project['tier'] = 'COMMUNITY';
        project['status'] = 'APPROVED';
      }
      data['facets']['types'] = [
        {'type': 'TOOL', 'count': 1},
      ];
      return json(data);
    case '/api/v1/me/preferences':
      return json(<String, Object?>{});
    case '/api/v1/auth/sessions':
      return json({
        'items': [
          {
            'id': 'current',
            'current': true,
            'deviceName': 'Linux · Thiết bị kiểm tra',
            'lastSeenAt': '2026-11-08T08:00:00Z',
          },
          {
            'id': 'other',
            'current': false,
            'deviceName': 'Android · Thiết bị kiểm tra',
          },
        ],
      });
    case '/api/v1/me/blocks':
      return json({
        'items': [
          {
            'id': 'audit-blocked',
            'username': 'thanhvienmau',
            'displayName': 'Thành viên mẫu',
            'bio': 'Dữ liệu giả lập để kiểm tra bố cục.',
          },
        ],
      });
    case '/api/v1/channels':
      return json({
        'items': [
          {
            'id': 'audit-channel',
            'slug': 'linux',
            'name': 'Linux Việt Nam',
            'minRoleToPost': 'MEMBER',
            'unreadCount': 3,
          },
        ],
      });
    case '/api/v1/channels/audit-channel/messages':
    case '/api/v1/dm/conversations/audit-dm/messages':
      return json({
        'items': [
          {
            'id': 'audit-message',
            'authorId': 'audit-peer',
            'author': _peer,
            'conversationId': 'audit-dm',
            'channelId': 'audit-channel',
            'content': 'Mình đang dùng Wayland. Tiếng Việt: ặ ữ ờ ẫ ệ',
            'createdAt': '2026-11-08T08:00:00Z',
            'reactions': [
              {'emoji': '👍', 'count': 2, 'viewerReacted': false},
            ],
          },
          {
            'id': 'audit-own-message',
            'authorId': 'audit-owner',
            'author': {
              'id': 'audit-owner',
              'username': 'kiemtra',
              'displayName': 'Thành viên kiểm tra',
            },
            'conversationId': 'audit-dm',
            'channelId': 'audit-channel',
            'content': 'Cảm ơn bạn đã chia sẻ cấu hình.',
            'createdAt': '2026-11-08T08:01:00Z',
          },
        ],
      });
    case '/api/v1/dm/conversations':
      return json({
        'items': [_conversation],
      });
    case '/api/v1/dm/conversations/audit-dm':
      return json(_conversation);
    case '/api/v1/feedback/mine':
      return json({
        'items': [_ticket],
      });
    case '/api/v1/feedback/$auditFeedbackId/messages':
      return json({
        'ticket': _ticket,
        'messages': [
          {
            'id': 'audit-reply',
            'staff': true,
            'mine': false,
            'content': 'Đội VNLF đã nhận góp ý. Cảm ơn bạn!',
            'createdAt': '2026-11-08T08:00:00Z',
          },
        ],
      });
    case '/api/v1/me/activity-calendar':
      final from = request.query['from']!;
      final to = request.query['to']!;
      final today = DateTime.now()
          .toUtc()
          .add(const Duration(hours: 7))
          .toIso8601String()
          .substring(0, 10);
      final count =
          DateTime.parse(to).difference(DateTime.parse(from)).inDays + 1;
      return json({
        'from': from,
        'to': to,
        'today': today,
        'totalPoints': 128,
        'earnedPoints': 40,
        'reversedPoints': 0,
        'currentStreak': 3,
        'longestStreak': 7,
        'days': List.generate(count, (i) {
          final day = DateTime.parse(from)
              .add(Duration(days: i))
              .toIso8601String()
              .substring(0, 10);
          final checked = day.compareTo(today) <= 0 && i % 3 != 0;
          return {
            'date': day,
            'checkedIn': checked,
            'points': checked ? 5 : 0,
            'streakDay': checked ? 1 : 0,
          };
        }),
      });
    case '/api/v1/projects/vnlf-cli':
      return json({
        'id': 'audit-project',
        'slug': 'vnlf-cli',
        'name': 'vnlf-cli',
        'tagline': 'Công cụ Linux cho cộng đồng Việt Nam',
        'intro': 'Hỗ trợ cấu hình hệ thống. Tiếng Việt: ặ ữ ờ ẫ ệ',
        'type': 'TOOL',
        'tier': 'COMMUNITY',
        'status': 'APPROVED',
        'owner': _peer,
        'rating': {'average': 4.5, 'count': 2},
        'myRating': 4,
        'canRate': true,
        'ratingDistribution': [0, 0, 0, 1, 1],
      });
    default:
      return fixtureTransport(request);
  }
}
