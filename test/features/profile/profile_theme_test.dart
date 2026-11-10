import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/features/profile/domain/profile_theme.dart';

void main() {
  test('an unknown theme falls back to vnlf', () {
    final theme = profileThemeColors('windows', null);

    expect(theme.light.accent, '#1d6b43');
    expect(theme.dark.coverTo, '#1d4a30');
    expect(theme.mono, isFalse);
    expect(profileThemeColors('terminal', null).mono, isTrue);
  });

  test('a picked accent stays readable in both modes', () {
    // Computed with the website's packages/contracts/src/name-color.ts.
    const vectors = {
      '#ff0000': ('#de0000', '#ff3528'),
      '#00ff00': ('#008000', '#00ff00'),
      '#3366ff': ('#2d5ff7', '#4e7fff'),
      '#ffcc00': ('#866a00', '#ffcc00'),
      '#7e22ce': ('#7e22ce', '#aa5fff'),
      '#000000': ('#000000', '#868686'),
      '#ffffff': ('#6e6e6e', '#ffffff'),
    };
    for (final MapEntry(key: picked, value: (light, dark)) in vectors.entries) {
      final theme = profileThemeColors('nord', picked.toUpperCase());
      expect(theme.light.accent, light, reason: picked);
      expect(theme.light.accentInk, '#ffffff', reason: picked);
      expect(theme.dark.accent, dark, reason: picked);
      expect(theme.dark.accentInk, '#000000', reason: picked);
      expect(theme.light.canvas, '#e5e9f0');
    }
  });

  test('an invalid accent is ignored', () {
    expect(profileThemeColors('arch', 'red').light.accent, '#0f6fa1');
    expect(profileThemeColors('arch', '#12345').dark.accent, '#38a8e0');
  });
}
