/// Profile fields the account owner may change through `PATCH /api/v1/me/profile`.
enum ProfileField { username, displayName, bio, website }

enum ProfileFieldError { required, tooShort, tooLong, invalidCharacters }

final class AccountProfile {
  const AccountProfile({
    required this.username,
    required this.displayName,
    this.bio = '',
    this.website = '',
  });

  final String username;
  final String displayName;
  final String bio;
  final String website;

  String valueOf(ProfileField field) => switch (field) {
    ProfileField.username => username,
    ProfileField.displayName => displayName,
    ProfileField.bio => bio,
    ProfileField.website => website,
  };

  AccountProfile apply(ProfilePatch patch) => AccountProfile(
    username: patch.fields[ProfileField.username] ?? username,
    displayName: patch.fields[ProfileField.displayName] ?? displayName,
    bio: patch.fields[ProfileField.bio] ?? bio,
    website: patch.fields[ProfileField.website] ?? website,
  );

  @override
  bool operator ==(Object other) =>
      other is AccountProfile &&
      other.username == username &&
      other.displayName == displayName &&
      other.bio == bio &&
      other.website == website;

  @override
  int get hashCode => Object.hash(username, displayName, bio, website);
}

/// Only the fields that differ from the loaded profile, already trimmed.
final class ProfilePatch {
  ProfilePatch(Map<ProfileField, String> fields)
    : fields = Map.unmodifiable(fields);

  final Map<ProfileField, String> fields;

  bool get isEmpty => fields.isEmpty;
}

final class ProfileDraftCheck {
  ProfileDraftCheck({
    required Map<ProfileField, ProfileFieldError> errors,
    required this.patch,
  }) : errors = Map.unmodifiable(errors);

  final Map<ProfileField, ProfileFieldError> errors;
  final ProfilePatch patch;

  bool get isValid => errors.isEmpty;
}

/// Server limits (UTF-16 code units, as the API counts JavaScript string
/// length): username 3-30 of `[A-Za-z0-9._]`, display name 1-80, bio 0-160,
/// website 0-500. Only changed fields are validated, so an unchanged legacy
/// value never blocks saving another field.
ProfileDraftCheck checkProfileDraft(
  AccountProfile original,
  AccountProfile draft,
) {
  final errors = <ProfileField, ProfileFieldError>{};
  final changed = <ProfileField, String>{};
  for (final field in ProfileField.values) {
    final value = draft.valueOf(field).trim();
    if (value == original.valueOf(field)) continue;
    final error = _validate(field, value);
    if (error != null) {
      errors[field] = error;
    } else {
      changed[field] = value;
    }
  }
  return ProfileDraftCheck(errors: errors, patch: ProfilePatch(changed));
}

final _usernamePattern = RegExp(r'^[A-Za-z0-9._]+$');

ProfileFieldError? _validate(ProfileField field, String value) {
  switch (field) {
    case ProfileField.username:
      if (value.isEmpty) return ProfileFieldError.required;
      if (value.length < 3) return ProfileFieldError.tooShort;
      if (value.length > 30) return ProfileFieldError.tooLong;
      if (!_usernamePattern.hasMatch(value)) {
        return ProfileFieldError.invalidCharacters;
      }
    case ProfileField.displayName:
      if (value.isEmpty) return ProfileFieldError.required;
      if (value.length > 80) return ProfileFieldError.tooLong;
    case ProfileField.bio:
      if (value.length > 160) return ProfileFieldError.tooLong;
    case ProfileField.website:
      if (value.length > 500) return ProfileFieldError.tooLong;
  }
  return null;
}
