import 'package:flutter/material.dart';

/// Semantic color tokens extracted from `vietnamlinuxfamily.net` (`:root` and `html.vnlf-dark`).
@immutable
class VnlfColors extends ThemeExtension<VnlfColors> {
  const VnlfColors({
    required this.bg,
    required this.paper,
    required this.surface,
    required this.surfaceSoft,
    required this.ink,
    required this.muted,
    required this.textSubtle,
    required this.line,
    required this.brand,
    required this.brandStrong,
    required this.brandSoft,
    required this.orange,
    required this.red,
    required this.blue,
    required this.green,
    required this.cyan,
    required this.purple,
    required this.amber,
    required this.tierPartner,
    required this.ratingStar,
    required this.codeBlockBg,
    required this.codeBlockText,
    required this.codeBlockPillBg,
    required this.socialIconBg,
    required this.isDark,
  });

  /// `--bg`: Screen canvas background (`#f5f6f4` light / `#0c0e0d` dark).
  final Color bg;

  /// `--paper`: Elevated surface / card canvas (`#ffffff` light / `#141715` dark).
  final Color paper;

  /// `--surface`: Main content card & component surface (`#ffffff` light / `#151816` dark).
  final Color surface;

  /// `--surface-soft`: Secondary / muted surface (`#f1f3f1` light / `#1b1f1c` dark).
  final Color surfaceSoft;

  /// `--ink`: Primary typography & high-contrast glyphs (`#141916` light / `#eceeec` dark).
  final Color ink;

  /// `--muted`: Secondary text, inactive tab labels, metadata (`#5b655e` light / `#9ba49d` dark).
  final Color muted;

  /// `--text-subtle`: Timestamps, subtle hints, vote score neutral (`#656f68` light / `#7d867f` dark).
  final Color textSubtle;

  /// `--line`: Borders, dividers, subtle outlines (`#e2e6e2` light / `#262b28` dark).
  final Color line;

  /// `--brand`: Primary brand accent (`#1d6b43` Emerald light / `#7fcf9a` Mint dark).
  final Color brand;

  /// `--brand-strong`: Deep brand background (`#10412a` light / `#0e3a24` dark).
  final Color brandStrong;

  /// `--brand-soft`: Subtle brand tint for chips and badges (`#e5f1e9` light / `#15291d` dark).
  final Color brandSoft;

  /// `--orange`: Warnings, voice status, attention pills (`#9a5b0c` light / `#e0a458` dark).
  final Color orange;

  /// `--red`: Downvote, destructive actions, errors (`#c0392b` light / `#f08a7e` dark).
  final Color red;

  /// `--blue`: Links, informational badges, Discord links (`#2f6e9e` light / `#86bade` dark).
  final Color blue;

  /// Semantic green accent for success badges and online indicators.
  final Color green;

  /// Semantic cyan accent for technical badges and terminal links.
  final Color cyan;

  /// Semantic purple accent for special roles and tags.
  final Color purple;

  /// Semantic amber accent for rank medals, warnings, and stars.
  final Color amber;

  /// `--tier-partner`: Partner / sponsor badge accent (`#8f5408` light / `#e8b45c` dark).
  final Color tierPartner;

  /// `--rating-star`: Rating stars, reputation indicators (`#d99a06` light / `#f2c14e` dark).
  final Color ratingStar;

  /// Terminal / code block forest-green background matching web production.
  final Color codeBlockBg;

  /// Primary monospace foreground inside code blocks.
  final Color codeBlockText;

  /// Copy button pill background inside code blocks.
  final Color codeBlockPillBg;

  /// Muted circular social icon fill in sidebar.
  final Color socialIconBg;

  /// Whether this palette represents `html.vnlf-dark`.
  final bool isDark;

  /// Production light palette (`:root`).
  static const VnlfColors light = VnlfColors(
    bg: Color(0xFFF5F6F4),
    paper: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceSoft: Color(0xFFF1F3F1),
    ink: Color(0xFF141916),
    muted: Color(0xFF5B655E),
    textSubtle: Color(0xFF656F68),
    line: Color(0xFFE2E6E2),
    brand: Color(0xFF1D6B43),
    brandStrong: Color(0xFF10412A),
    brandSoft: Color(0xFFE5F1E9),
    orange: Color(0xFF9A5B0C),
    red: Color(0xFFC0392B),
    blue: Color(0xFF2F6E9E),
    green: Color(0xFF16A34A),
    cyan: Color(0xFF0284C7),
    purple: Color(0xFF7C3AED),
    amber: Color(0xFFD97706),
    tierPartner: Color(0xFF8F5408),
    ratingStar: Color(0xFFD99A06),
    codeBlockBg: Color(0xFF113B26),
    codeBlockText: Color(0xFFE2F5EA),
    codeBlockPillBg: Color(0xFF1C4C34),
    socialIconBg: Color(0xFFA0A8A2),
    isDark: false,
  );

  /// Production dark palette (`html.vnlf-dark`).
  static const VnlfColors dark = VnlfColors(
    bg: Color(0xFF0C0E0D),
    paper: Color(0xFF141715),
    surface: Color(0xFF151816),
    surfaceSoft: Color(0xFF1B1F1C),
    ink: Color(0xFFECEEEC),
    muted: Color(0xFF9BA49D),
    textSubtle: Color(0xFF7D867F),
    line: Color(0xFF262B28),
    brand: Color(0xFF7FCF9A),
    brandStrong: Color(0xFF0E3A24),
    brandSoft: Color(0xFF15291D),
    orange: Color(0xFFE0A458),
    red: Color(0xFFF08A7E),
    blue: Color(0xFF86BADE),
    green: Color(0xFF4ADE80),
    cyan: Color(0xFF38BDF8),
    purple: Color(0xFFC084FC),
    amber: Color(0xFFFBBF24),
    tierPartner: Color(0xFFE8B45C),
    ratingStar: Color(0xFFF2C14E),
    codeBlockBg: Color(0xFF0D2B1C),
    codeBlockText: Color(0xFFDFF4E8),
    codeBlockPillBg: Color(0xFF163D29),
    socialIconBg: Color(0xFF434C46),
    isDark: true,
  );

  /// Resolves the active [VnlfColors] from [context], falling back to [light].
  static VnlfColors of(BuildContext context) {
    return Theme.of(context).extension<VnlfColors>() ?? light;
  }

  @override
  VnlfColors copyWith({
    Color? bg,
    Color? paper,
    Color? surface,
    Color? surfaceSoft,
    Color? ink,
    Color? muted,
    Color? textSubtle,
    Color? line,
    Color? brand,
    Color? brandStrong,
    Color? brandSoft,
    Color? orange,
    Color? red,
    Color? blue,
    Color? green,
    Color? cyan,
    Color? purple,
    Color? amber,
    Color? tierPartner,
    Color? ratingStar,
    Color? codeBlockBg,
    Color? codeBlockText,
    Color? codeBlockPillBg,
    Color? socialIconBg,
    bool? isDark,
  }) {
    return VnlfColors(
      bg: bg ?? this.bg,
      paper: paper ?? this.paper,
      surface: surface ?? this.surface,
      surfaceSoft: surfaceSoft ?? this.surfaceSoft,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      textSubtle: textSubtle ?? this.textSubtle,
      line: line ?? this.line,
      brand: brand ?? this.brand,
      brandStrong: brandStrong ?? this.brandStrong,
      brandSoft: brandSoft ?? this.brandSoft,
      orange: orange ?? this.orange,
      red: red ?? this.red,
      blue: blue ?? this.blue,
      green: green ?? this.green,
      cyan: cyan ?? this.cyan,
      purple: purple ?? this.purple,
      amber: amber ?? this.amber,
      tierPartner: tierPartner ?? this.tierPartner,
      ratingStar: ratingStar ?? this.ratingStar,
      codeBlockBg: codeBlockBg ?? this.codeBlockBg,
      codeBlockText: codeBlockText ?? this.codeBlockText,
      codeBlockPillBg: codeBlockPillBg ?? this.codeBlockPillBg,
      socialIconBg: socialIconBg ?? this.socialIconBg,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  VnlfColors lerp(ThemeExtension<VnlfColors>? other, double t) {
    if (other is! VnlfColors) return this;
    return VnlfColors(
      bg: Color.lerp(bg, other.bg, t)!,
      paper: Color.lerp(paper, other.paper, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceSoft: Color.lerp(surfaceSoft, other.surfaceSoft, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      textSubtle: Color.lerp(textSubtle, other.textSubtle, t)!,
      line: Color.lerp(line, other.line, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      brandStrong: Color.lerp(brandStrong, other.brandStrong, t)!,
      brandSoft: Color.lerp(brandSoft, other.brandSoft, t)!,
      orange: Color.lerp(orange, other.orange, t)!,
      red: Color.lerp(red, other.red, t)!,
      blue: Color.lerp(blue, other.blue, t)!,
      green: Color.lerp(green, other.green, t)!,
      cyan: Color.lerp(cyan, other.cyan, t)!,
      purple: Color.lerp(purple, other.purple, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
      tierPartner: Color.lerp(tierPartner, other.tierPartner, t)!,
      ratingStar: Color.lerp(ratingStar, other.ratingStar, t)!,
      codeBlockBg: Color.lerp(codeBlockBg, other.codeBlockBg, t)!,
      codeBlockText: Color.lerp(codeBlockText, other.codeBlockText, t)!,
      codeBlockPillBg: Color.lerp(codeBlockPillBg, other.codeBlockPillBg, t)!,
      socialIconBg: Color.lerp(socialIconBg, other.socialIconBg, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}
