import 'dart:math' as math;

/// One mode's colours of a profile theme, as `#rrggbb`.
final class ProfileThemeColors {
  const ProfileThemeColors({
    required this.accent,
    required this.accentInk,
    required this.canvas,
    required this.coverFrom,
    required this.coverTo,
  });

  final String accent;

  /// Text drawn on the accent.
  final String accentInk;

  /// The page behind the profile's cards.
  final String canvas;

  /// The cover band without an image: a 135° gradient between these two.
  final String coverFrom;
  final String coverTo;

  ProfileThemeColors _withAccent(String accent) => ProfileThemeColors(
    accent: accent,
    accentInk: inkOn(accent),
    canvas: canvas,
    coverFrom: coverFrom,
    coverTo: coverTo,
  );
}

/// A profile theme's colours in both modes. Only `terminal` is [mono]: the
/// website writes its handle, status and numbers in a monospace font.
typedef ProfileTheme = ({
  ProfileThemeColors light,
  ProfileThemeColors dark,
  bool mono,
});

ProfileTheme _theme(
  List<String> light,
  List<String> dark, {
  bool mono = false,
}) {
  ProfileThemeColors colors(List<String> values) => ProfileThemeColors(
    accent: values[0],
    accentInk: values[1],
    canvas: values[2],
    coverFrom: values[3],
    coverTo: values[4],
  );
  return (light: colors(light), dark: colors(dark), mono: mono);
}

/// The website's `PROFILE_THEMES` (`packages/contracts/src/profile-themes.ts`):
/// accent, ink on the accent, canvas, and the two cover colours.
final profileThemes = <String, ProfileTheme>{
  'vnlf': _theme(
    ['#1d6b43', '#ffffff', '#eef3ef', '#d8eadf', '#b9dcc6'],
    ['#7fcf9a', '#0c0e0d', '#101512', '#14301f', '#1d4a30'],
  ),
  'nord': _theme(
    ['#3b6ea8', '#ffffff', '#e5e9f0', '#d8dee9', '#81a1c1'],
    ['#88c0d0', '#2e3440', '#2e3440', '#3b4252', '#5e81ac'],
  ),
  'gruvbox': _theme(
    ['#9d3f04', '#fbf1c7', '#f2e5bc', '#ebdbb2', '#d79921'],
    ['#fabd2f', '#282828', '#282828', '#3c3836', '#b57614'],
  ),
  'dracula': _theme(
    ['#6a3fc8', '#ffffff', '#efedf7', '#e4dcf7', '#bd93f9'],
    ['#bd93f9', '#282a36', '#282a36', '#44475a', '#6272a4'],
  ),
  'catppuccin': _theme(
    ['#7a2fe0', '#ffffff', '#eff1f5', '#dce0e8', '#cba6f7'],
    ['#cba6f7', '#1e1e2e', '#1e1e2e', '#313244', '#585b70'],
  ),
  'solarized': _theme(
    ['#1a6ea6', '#fdf6e3', '#fdf6e3', '#eee8d5', '#93a1a1'],
    ['#2aa1d6', '#002b36', '#002b36', '#073642', '#268bd2'],
  ),
  'tokyoNight': _theme(
    ['#2e5fbf', '#ffffff', '#e1e2e7', '#d5d6db', '#9aa5ce'],
    ['#7aa2f7', '#1a1b26', '#1a1b26', '#24283b', '#414868'],
  ),
  'ubuntu': _theme(
    ['#c34113', '#ffffff', '#f7ebe6', '#f4d3c4', '#e95420'],
    ['#f47c4f', '#2c001e', '#2c001e', '#5e2750', '#2c001e'],
  ),
  'fedora': _theme(
    ['#2f5ea3', '#ffffff', '#e8eef7', '#d6e2f3', '#51a2da'],
    ['#6cb2e8', '#0b1a2c', '#0b1a2c', '#294172', '#0b1a2c'],
  ),
  'arch': _theme(
    ['#0f6fa1', '#ffffff', '#e9f3f9', '#d3e9f5', '#1793d1'],
    ['#38a8e0', '#0d1b24', '#0d1b24', '#11384d', '#0d1b24'],
  ),
  'debian': _theme(
    ['#c20a4b', '#ffffff', '#f9e8ee', '#f4cddb', '#d70a53'],
    ['#ff5c8f', '#2a0a15', '#21080f', '#4a0f24', '#21080f'],
  ),
  'terminal': _theme(
    ['#0b7a2c', '#ffffff', '#e7f3ea', '#cfe9d6', '#0b7a2c'],
    ['#33ff77', '#000000', '#000000', '#001a08', '#003d14'],
    mono: true,
  ),
};

final _hex = RegExp(r'^#[0-9a-f]{6}$', caseSensitive: false);

/// The website's `profileThemeColors`: the theme's colours (`vnlf` for an
/// unknown id), with a picked accent made readable in each mode.
ProfileTheme profileThemeColors(String? themeId, String? accentColor) {
  final theme = profileThemes[themeId] ?? profileThemes['vnlf']!;
  if (accentColor == null || !_hex.hasMatch(accentColor)) return theme;
  final accent = accentColor.toLowerCase();
  return (
    light: theme.light._withAccent(readableColor(accent, dark: false)),
    dark: theme.dark._withAccent(readableColor(accent, dark: true)),
    mono: theme.mono,
  );
}

/// White or black, whichever reads better on [hex].
String inkOn(String hex) {
  final color = _rgb(hex);
  return _contrast(_rgb('#ffffff'), color) >= _contrast(_rgb('#000000'), color)
      ? '#ffffff'
      : '#000000';
}

// The website's `name-color.ts`: keep the picked colour's hue and chroma in
// OKLCH and move only its lightness until it reaches 4.6:1 on every surface.
const _lightSurfaces = ['#ffffff', '#f5f6f4', '#f1f3f1'];
const _darkSurfaces = ['#0c0e0d', '#141715', '#151816', '#1b1f1c'];
const _target = 4.6;

typedef _Rgb = (double, double, double);

/// [hex] as shown on the website's light or dark surfaces, changed only as
/// much as it takes to stay readable.
String readableColor(String hex, {required bool dark}) {
  final surfaces = (dark ? _darkSurfaces : _lightSurfaces).map(_rgb).toList();
  final (l, c, h) = _toOklch(_rgb(hex));
  double worst(_Rgb color) =>
      surfaces.map((surface) => _contrast(color, surface)).reduce(math.min);
  final original = _inSrgb(l, c, h);
  if (worst(original) >= _target) return _toHex(original);
  // Light surfaces need a darker colour and dark ones a lighter colour: find
  // the smallest change that passes.
  var low = dark ? l : 0.0;
  var high = dark ? 1.0 : l;
  for (var i = 0; i < 30; i++) {
    final mid = (low + high) / 2;
    final passes = worst(_inSrgb(mid, c, h)) >= _target;
    if (dark == passes) {
      high = mid;
    } else {
      low = mid;
    }
  }
  return _toHex(_inSrgb(dark ? high : low, c, h));
}

_Rgb _rgb(String hex) => (
  int.parse(hex.substring(1, 3), radix: 16) / 255,
  int.parse(hex.substring(3, 5), radix: 16) / 255,
  int.parse(hex.substring(5, 7), radix: 16) / 255,
);

String _toHex(_Rgb rgb) {
  String channel(double value) =>
      (value.clamp(0.0, 1.0) * 255).round().toRadixString(16).padLeft(2, '0');
  return '#${channel(rgb.$1)}${channel(rgb.$2)}${channel(rgb.$3)}';
}

double _toLinear(double c) =>
    c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _fromLinear(double c) => c <= 0.0031308
    ? 12.92 * c
    : 1.055 * c.sign * math.pow(c.abs(), 1 / 2.4) - 0.055;

double _luminance(_Rgb rgb) =>
    0.2126 * _toLinear(rgb.$1) +
    0.7152 * _toLinear(rgb.$2) +
    0.0722 * _toLinear(rgb.$3);

double _contrast(_Rgb a, _Rgb b) {
  final x = _luminance(a), y = _luminance(b);
  return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05);
}

double _cbrt(double value) => value < 0
    ? -math.pow(-value, 1 / 3).toDouble()
    : math.pow(value, 1 / 3).toDouble();

// Björn Ottosson's OKLab (https://bottosson.github.io/posts/oklab/), in polar
// form, with the website's constants.
(double, double, double) _toOklch(_Rgb rgb) {
  final r = _toLinear(rgb.$1), g = _toLinear(rgb.$2), b = _toLinear(rgb.$3);
  final l = _cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
  final m = _cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
  final s = _cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
  final a = 1.9779984951 * l - 2.428592205 * m + 0.4505937099 * s;
  final bb = 0.0259040371 * l + 0.7827717662 * m - 0.808675766 * s;
  return (
    0.2104542553 * l + 0.793617785 * m - 0.0040720468 * s,
    math.sqrt(a * a + bb * bb),
    math.atan2(bb, a),
  );
}

_Rgb _fromOklch(double lightness, double chroma, double hue) {
  final a = chroma * math.cos(hue), b = chroma * math.sin(hue);
  final l = math.pow(lightness + 0.3963377774 * a + 0.2158037573 * b, 3);
  final m = math.pow(lightness - 0.1055613458 * a - 0.0638541728 * b, 3);
  final s = math.pow(lightness - 0.0894841775 * a - 1.291485548 * b, 3);
  return (
    _fromLinear(4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s),
    _fromLinear(-1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s),
    _fromLinear(-0.0041960863 * l - 0.7034186147 * m + 1.707614701 * s),
  );
}

bool _inGamut(_Rgb rgb) =>
    [rgb.$1, rgb.$2, rgb.$3].every((c) => c >= -1e-4 && c <= 1 + 1e-4);

/// The largest chroma up to [chroma] that fits sRGB at this lightness.
_Rgb _inSrgb(double lightness, double chroma, double hue) {
  final full = _fromOklch(lightness, chroma, hue);
  if (_inGamut(full)) return full;
  var low = 0.0, high = chroma;
  for (var i = 0; i < 24; i++) {
    final mid = (low + high) / 2;
    if (_inGamut(_fromOklch(lightness, mid, hue))) {
      low = mid;
    } else {
      high = mid;
    }
  }
  return _fromOklch(lightness, low, hue);
}
