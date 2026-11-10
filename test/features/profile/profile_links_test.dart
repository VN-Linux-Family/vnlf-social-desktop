import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/features/profile/domain/profile_links.dart';

// The cases of the website's apps/api/tests/profile-links.test.ts.
void main() {
  test('keeps http(s) links and adds https:// when the scheme is missing', () {
    final github = parseProfileLink('https://github.com/dungle')!;
    expect(
      (github.url, github.platform, github.label),
      ('https://github.com/dungle', LinkPlatform.github, 'dungle'),
    );
    final blog = parseProfileLink('http://example.com/blog')!;
    expect(
      (blog.url, blog.platform, blog.label),
      ('http://example.com/blog', null, 'example.com'),
    );
    final dotfiles = parseProfileLink('  github.com/dungle/dotfiles ')!;
    expect(
      (dotfiles.url, dotfiles.label),
      ('https://github.com/dungle/dotfiles', 'dungle/dotfiles'),
    );
    final upper = parseProfileLink('HTTPS://WWW.Example.COM')!;
    expect(
      (upper.url, upper.label),
      ('https://www.example.com/', 'example.com'),
    );
  });

  test('refuses anything that is not a plain web link', () {
    for (final bad in [
      '',
      '   ',
      'javascript:alert(1)',
      'data:text/html,hi',
      'mailto:a@b.vn',
      'ftp://example.com',
      'https://user:pass@example.com',
      'https://user@example.com',
      'https://localhost/x',
      'http://127.0.0.1/',
      'https://[::1]/',
      'https://intranet/',
      'https://exa mple.com',
      'https://example.com/\u202egnp.exe',
      'https://example.com.',
      'https://example.com/${'a' * 200}',
    ]) {
      expect(parseProfileLink(bad), isNull, reason: bad);
    }
    expect(parseProfileLink('https://example.com/${'a' * 170}'), isNotNull);
  });

  test('finds the platform from the host and its subdomains only', () {
    const cases = <(String, LinkPlatform?)>[
      ('https://www.facebook.com/dungle', LinkPlatform.facebook),
      ('https://fb.com/dungle', LinkPlatform.facebook),
      ('https://m.facebook.com/dungle', LinkPlatform.facebook),
      ('https://instagram.com/dungle', LinkPlatform.instagram),
      ('https://youtu.be/dQw4w9WgXcQ', LinkPlatform.youtube),
      ('https://music.youtube.com/@dungle', LinkPlatform.youtube),
      ('https://www.tiktok.com/@dungle', LinkPlatform.tiktok),
      ('https://gitlab.com/dungle', LinkPlatform.gitlab),
      ('https://twitter.com/dungle', LinkPlatform.x),
      ('https://x.com/dungle', LinkPlatform.x),
      ('https://www.threads.net/@dungle', LinkPlatform.threads),
      ('https://old.reddit.com/u/dungle', LinkPlatform.reddit),
      ('https://t.me/dungle', LinkPlatform.telegram),
      ('https://discord.gg/vnlf', LinkPlatform.discord),
      ('https://discord.com/invite/vnlf', LinkPlatform.discord),
      ('https://www.linkedin.com/in/dungle', LinkPlatform.linkedin),
      ('https://www.twitch.tv/dungle', LinkPlatform.twitch),
      ('https://codeberg.org/dungle', LinkPlatform.codeberg),
      ('https://bsky.app/profile/dungle.bsky.social', LinkPlatform.bluesky),
      ('https://zalo.me/0912345678', LinkPlatform.zalo),
      ('https://mastodon.social/@dungle', null),
      ('https://dungle.github.io', null),
      ('https://notgithub.com/dungle', null),
      ('https://github.com.evil.io/dungle', null),
      ('https://facebook.com-login.vn/x', null),
    ];
    for (final (url, platform) in cases) {
      expect(parseProfileLink(url)?.platform, platform, reason: url);
    }
    expect(linkPlatform('GIST.GitHub.com'), LinkPlatform.github);
  });

  test('labels a button with the handle from the link, or the domain', () {
    String? label(String url) => parseProfileLink(url)?.label;
    expect(label('https://instagram.com/dung.le'), '@dung.le');
    expect(label('https://instagram.com/p/AbCdEf'), 'instagram.com');
    expect(
      label('https://www.youtube.com/@VietnamLinuxFamily'),
      '@VietnamLinuxFamily',
    );
    expect(label('https://www.youtube.com/channel/UC123'), 'youtube.com');
    expect(label('https://youtu.be/dQw4w9WgXcQ'), 'youtu.be');
    expect(label('https://www.tiktok.com/@dungle/video/1'), '@dungle');
    expect(label('https://x.com/dungle_vn'), '@dungle_vn');
    expect(label('https://www.reddit.com/r/linux'), 'r/linux');
    expect(label('https://www.reddit.com/user/dungle'), 'u/dungle');
    expect(label('https://www.linkedin.com/in/dung-le'), 'dung-le');
    expect(label('https://discord.com/invite/vnlf'), 'discord.gg/vnlf');
    expect(
      label('https://bsky.app/profile/dungle.bsky.social'),
      '@dungle.bsky.social',
    );
    expect(
      label('https://www.facebook.com/profile.php?id=1000'),
      'facebook.com',
    );
    expect(label('https://t.me/+AbCdEf'), 't.me');
    expect(label('https://zalo.me/0912345678'), 'zalo.me');
    expect(label('https://github.com/%E2%80%AEevil'), 'github.com');
    expect(label('https://github.com/ng%C6%B0%E1%BB%9Di'), 'người');
  });
}
