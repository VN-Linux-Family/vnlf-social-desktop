import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/features/settings/domain/account_profile.dart';

const _original = AccountProfile(
  username: 'minh.linux',
  displayName: 'Minh',
  bio: 'Xin chào',
  website: 'https://example.org',
);

AccountProfile _with({
  String? username,
  String? displayName,
  String? bio,
  String? website,
}) => AccountProfile(
  username: username ?? _original.username,
  displayName: displayName ?? _original.displayName,
  bio: bio ?? _original.bio,
  website: website ?? _original.website,
);

void main() {
  test('an unchanged draft produces an empty patch', () {
    final check = checkProfileDraft(_original, _with());
    expect(check.isValid, isTrue);
    expect(check.patch.isEmpty, isTrue);
  });

  test('only trimmed, changed fields enter the patch', () {
    final check = checkProfileDraft(
      _original,
      _with(displayName: '  Tiếng Việt: ặ ữ ờ ẫ ệ  ', bio: 'Xin chào'),
    );
    expect(check.patch.fields, {
      ProfileField.displayName: 'Tiếng Việt: ặ ữ ờ ẫ ệ',
    });
  });

  test('username follows the server pattern and 3-30 length', () {
    ProfileFieldError? error(String value) => checkProfileDraft(
      _original,
      _with(username: value),
    ).errors[ProfileField.username];
    expect(error(''), ProfileFieldError.required);
    expect(error('ab'), ProfileFieldError.tooShort);
    expect(error('a' * 31), ProfileFieldError.tooLong);
    expect(error('có dấu'), ProfileFieldError.invalidCharacters);
    expect(error('has space'), ProfileFieldError.invalidCharacters);
    expect(error('a-b'), ProfileFieldError.invalidCharacters);
    expect(error('a' * 30), isNull);
    expect(error('A_b.9'), isNull);
  });

  test('display name, bio and website respect UTF-16 limits', () {
    final check = checkProfileDraft(
      _original,
      _with(displayName: '   ', bio: 'x' * 161, website: 'h' * 501),
    );
    expect(check.errors, {
      ProfileField.displayName: ProfileFieldError.required,
      ProfileField.bio: ProfileFieldError.tooLong,
      ProfileField.website: ProfileFieldError.tooLong,
    });
    expect(checkProfileDraft(_original, _with(bio: '😀' * 80)).isValid, isTrue);
    expect(checkProfileDraft(_original, _with(bio: '😀' * 81)).errors, {
      ProfileField.bio: ProfileFieldError.tooLong,
    });
  });

  test('clearing bio and website is a valid change to empty strings', () {
    final check = checkProfileDraft(_original, _with(bio: '', website: ' '));
    expect(check.patch.fields, {
      ProfileField.bio: '',
      ProfileField.website: '',
    });
  });

  test('an unchanged legacy value does not block other fields', () {
    const legacy = AccountProfile(username: 'ab', displayName: 'Minh');
    final check = checkProfileDraft(
      legacy,
      const AccountProfile(username: 'ab', displayName: 'Minh Mới'),
    );
    expect(check.isValid, isTrue);
    expect(check.patch.fields, {ProfileField.displayName: 'Minh Mới'});
  });

  test('apply merges a patch onto the profile', () {
    final applied = _original.apply(
      ProfilePatch({ProfileField.username: 'new_name'}),
    );
    expect(applied.username, 'new_name');
    expect(applied.displayName, 'Minh');
  });
}
