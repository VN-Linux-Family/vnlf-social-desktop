import '../../../core/api_client.dart';

enum DmPolicy { everyone, following }

final class WebsitePreferences {
  const WebsitePreferences({
    this.dmPolicy = DmPolicy.everyone,
    this.leaderboardVisible = true,
    this.onlineVisible = true,
    this.likeNotifications = true,
    this.followNotifications = true,
    this.messageNotifications = true,
    this.messageSoundEnabled = true,
    this.reduceMotion = false,
  });

  final DmPolicy dmPolicy;
  final bool leaderboardVisible;
  final bool onlineVisible;
  final bool likeNotifications;
  final bool followNotifications;
  final bool messageNotifications;
  final bool messageSoundEnabled;
  final bool reduceMotion;

  factory WebsitePreferences.fromJson(Map<String, dynamic>? json) {
    final values = json ?? const <String, dynamic>{};
    bool readBool(String key, bool fallback) {
      if (!values.containsKey(key)) return fallback;
      final value = values[key];
      if (value is! bool) throw ParseFailure('preferences.$key');
      return value;
    }

    final policy = values.containsKey('dmPolicy') ? values['dmPolicy'] : 'EVERYONE';
    if (policy != 'EVERYONE' && policy != 'FOLLOWING') {
      throw const ParseFailure('preferences.dmPolicy');
    }
    return WebsitePreferences(
      dmPolicy: policy == 'EVERYONE' ? DmPolicy.everyone : DmPolicy.following,
      leaderboardVisible: !readBool('leaderboardOptOut', false),
      onlineVisible: readBool('onlineVisible', true),
      likeNotifications: readBool('likeNotifications', true),
      followNotifications: readBool('followNotifications', true),
      messageNotifications: readBool('messageNotifications', true),
      messageSoundEnabled: readBool('messageSoundEnabled', true),
      reduceMotion: readBool('reduceMotion', false),
    );
  }

  Map<String, Object> toJson() => {
    'dmPolicy': dmPolicy == DmPolicy.everyone ? 'EVERYONE' : 'FOLLOWING',
    'leaderboardOptOut': !leaderboardVisible,
    'onlineVisible': onlineVisible,
    'likeNotifications': likeNotifications,
    'followNotifications': followNotifications,
    'messageNotifications': messageNotifications,
    'messageSoundEnabled': messageSoundEnabled,
    'reduceMotion': reduceMotion,
  };

  WebsitePreferences copyWith({DmPolicy? dmPolicy, bool? leaderboardVisible, bool? onlineVisible, bool? likeNotifications, bool? followNotifications, bool? messageNotifications, bool? messageSoundEnabled, bool? reduceMotion}) => WebsitePreferences(
    dmPolicy: dmPolicy ?? this.dmPolicy,
    leaderboardVisible: leaderboardVisible ?? this.leaderboardVisible,
    onlineVisible: onlineVisible ?? this.onlineVisible,
    likeNotifications: likeNotifications ?? this.likeNotifications,
    followNotifications: followNotifications ?? this.followNotifications,
    messageNotifications: messageNotifications ?? this.messageNotifications,
    messageSoundEnabled: messageSoundEnabled ?? this.messageSoundEnabled,
    reduceMotion: reduceMotion ?? this.reduceMotion,
  );
}
