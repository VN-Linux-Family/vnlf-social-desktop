import 'dart:convert';

import '../../../core/session_storage_contract.dart';
import '../../../domain/models.dart';
import '../domain/composer_draft.dart';
import '../domain/composer_poll.dart';
import '../../../data/field_reader.dart';
import 'composer_repository.dart';

final class RecoveredComposition {
  const RecoveredComposition(this.draft, this.dirty, this.publishKey);
  final ComposerDraft draft;
  final bool dirty;
  final String? publishKey;
}

/// Draft content stays in platform secure storage, partitioned by owner and slot.
/// Upload signatures, session headers and credentials are never included.
final class ComposerRecovery {
  const ComposerRecovery(this._storage);
  final SessionStorage _storage;
  String _key(String userId, String slot) =>
      'vnlf.composer.${Uri.encodeComponent(userId)}.${Uri.encodeComponent(slot)}';
  Future<RecoveredComposition?> read(
    String userId, {
    String slot = 'new',
  }) async {
    final raw = await _storage.read(_key(userId, slot));
    if (raw == null) return null;
    try {
      final value = jsonDecode(raw) as Map<String, dynamic>;
      if (value['schema'] != 1) throw const FormatException();
      final json = value['draft'] as Map<String, dynamic>;
      // An unsaved local composition intentionally has no server ID yet.
      final draft = draftFromJson({
        ...json,
        'id': json['id'] == '' ? 'local' : json['id'],
      });
      final rawPoll = objectValue(json['localPoll'], 'recovery.localPoll');
      return RecoveredComposition(
        draft.copyWith(
          id: json['id'] as String,
          pollDraft: json.containsKey('localPoll')
              ? rawPoll == null
                    ? null
                    : ComposerPollDraft(
                        stringValue(
                          rawPoll['question'],
                          'recovery.poll.question',
                        ),
                        stringList(rawPoll['options'], 'recovery.poll.options'),
                      )
              : draft.pollDraft,
          pollChanged: json['localPollChanged'] == true,
        ),
        value['dirty'] == true,
        value['publishKey'] as String?,
      );
    } catch (_) {
      throw const ParseFailure('composer.recovery');
    }
  }

  Future<void> write(
    String userId,
    RecoveredComposition value, {
    String slot = 'new',
  }) =>
      value.draft.status == 'PUBLISHED' &&
          !value.dirty &&
          value.publishKey == null
      ? clear(userId, slot: slot)
      : _storage.write(
          _key(userId, slot),
          jsonEncode({
            'schema': 1,
            'dirty': value.dirty,
            'publishKey': value.publishKey,
            'draft': {
              'id': value.draft.id,
              'version': value.draft.version,
              'format': value.draft.format,
              'title': value.draft.title,
              'excerpt': value.draft.excerpt,
              'contentJson': value.draft.document,
              'tags': value.draft.tags,
              'status': value.draft.status,
              'slug': value.draft.slug,
              'coverAssetId': value.draft.coverAssetId,
              'coverUrl': value.draft.coverUrl,
              'coverAlt': value.draft.coverAlt,
              'publishedAt': value.draft.publishedAt,
              'localPoll': value.draft.pollDraft == null
                  ? null
                  : {
                      'question': value.draft.pollDraft!.question,
                      'options': value.draft.pollDraft!.options,
                    },
              'localPollChanged': value.draft.pollChanged,
              'poll': value.draft.poll == null
                  ? null
                  : {
                      'id': value.draft.poll!.id,
                      'question': value.draft.poll!.question,
                      'options': [
                        for (final option in value.draft.poll!.options)
                          {
                            'id': option.id,
                            'label': option.label,
                            'votes': option.votes,
                          },
                      ],
                      'totalVotes': value.draft.poll!.totalVotes,
                      'viewerOptionId': value.draft.poll!.viewerOptionId,
                    },
              'attachments': value.draft.media.map(_media).toList(),
              'assets': value.draft.assets.values.map(_media).toList(),
            },
          }),
        );
  Future<void> clear(String userId, {String slot = 'new'}) =>
      _storage.delete(_key(userId, slot));
}

Map<String, dynamic> _media(DraftMedia media) => {
  'id': media.id,
  'url': media.url,
  'mime': media.mime,
  'alt': media.alt,
  'status': media.status,
  'state': media.state,
  'placement': media.placement,
  'error': media.error,
  'width': media.width,
  'height': media.height,
  'posterUrl': media.posterUrl,
  'durationMs': media.durationMs,
};
