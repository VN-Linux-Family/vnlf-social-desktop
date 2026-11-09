import 'dart:async';

/// What a chime announces, named as in the website's `community-sounds.tsx`.
enum CommunitySound { dm, channel, mention, voiceMessage, voiceJoin }

/// The website's two chimes: two notes for a message, three for someone
/// joining a voice room. `tool/generate_community_sounds.py` writes them.
enum CommunityChime {
  message('message.wav'),
  voiceJoin('voice-join.wav');

  const CommunityChime(this.file);

  /// The file under `assets/sounds/`.
  final String file;
}

/// Plays one chime. The output reports its own failures.
typedef PlayChime = Future<void> Function(CommunityChime chime);

/// The website's rules for chimes: an event rings once, nothing rings while
/// the member has turned sounds off, and a chime rings at most once every
/// 750 ms so that a burst of messages does not ring for each one.
final class CommunitySounds {
  CommunitySounds(this._play, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final PlayChime _play;
  final DateTime Function() _now;
  final _seen = <String>{};
  final _lastPlayed = <CommunityChime, DateTime>{};

  static const _remembered = 1000;
  static const _gap = Duration(milliseconds: 750);

  /// Rings for [kind] unless [eventId] already rang or was muted, sounds are
  /// off, or the same chime rang less than 750 ms ago. True when it rang.
  bool play(CommunitySound kind, String eventId, {required bool enabled}) {
    if (!_seen.add('${kind.name}:$eventId')) return false;
    if (_seen.length > _remembered) _seen.remove(_seen.first);
    if (!enabled) return false;
    final chime = kind == CommunitySound.voiceJoin
        ? CommunityChime.voiceJoin
        : CommunityChime.message;
    final now = _now();
    final last = _lastPlayed[chime];
    if (last != null && now.difference(last) < _gap) return false;
    _lastPlayed[chime] = now;
    unawaited(_play(chime));
    return true;
  }
}

/// The chime for a realtime event, as the website's `message-awareness.tsx`
/// picks it: a direct message, or a channel message that mentions the viewer
/// or not. Null for the viewer's own messages and for every other event.
({CommunitySound kind, String id})? messageSound(
  String type,
  Object? data,
  String viewerId,
) {
  if (type != 'dm:message-created' && type != 'message:created') return null;
  if (viewerId.isEmpty || data is! Map<String, Object?>) return null;
  final id = data['id'];
  if (id is! String || id.isEmpty || data['authorId'] == viewerId) return null;
  if (type == 'dm:message-created') return (kind: CommunitySound.dm, id: id);
  final attention = data['attentionUserIds'];
  final mentioned = attention is List && attention.contains(viewerId);
  return (
    kind: mentioned ? CommunitySound.mention : CommunitySound.channel,
    id: id,
  );
}
