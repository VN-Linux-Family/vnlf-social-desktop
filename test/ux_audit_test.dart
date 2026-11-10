import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vnlfsocialapp/main.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/design_system/design_system.dart';
import 'package:fleather/fleather.dart';
import 'package:vnlfsocialapp/src/features/composer/presentation/composer_editor.dart';
import 'package:vnlfsocialapp/src/features/composer/presentation/composer_toolbar.dart';
import 'package:vnlfsocialapp/src/features/discover/presentation/discover_articles.dart';
import 'package:vnlfsocialapp/src/features/shared/presentation/feature_samples.dart';
import 'package:vnlfsocialapp/src/features/feed/presentation/post_mapper.dart';

import '../tool/ux_audit_fixtures.dart';
import '../tool/ux_audit_surfaces.dart';

import 'package:vnlfsocialapp/src/features/voice/presentation/voice_providers.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader('BeVietnamPro');
    for (final weight in [
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
      'ExtraBold',
    ]) {
      loader.addFont(rootBundle.load('assets/fonts/BeVietnamPro-$weight.ttf'));
    }
    await loader.load();
  });
  test(
    'navigation uses the requested breakpoints including fractional widths',
    () {
      expect(VnlfViewportSize.fromWidth(839.9), VnlfViewportSize.mobile);
      expect(VnlfViewportSize.fromWidth(840), VnlfViewportSize.tablet);
      expect(VnlfViewportSize.fromWidth(1180.9), VnlfViewportSize.tablet);
      expect(VnlfViewportSize.fromWidth(1181), VnlfViewportSize.desktop);
    },
  );
  for (final theme in [VnlfTheme.light(), VnlfTheme.dark()]) {
    test(
      '${theme.brightness.name} Material text slots use VNLF typography',
      () {
        // design-system/MASTER.md: all text 13px; only page titles are 18px.
        expect(theme.textTheme.titleLarge!.fontSize, 18);
        expect(theme.textTheme.titleSmall!.fontSize, 13);
        expect(theme.textTheme.bodyLarge!.fontSize, 13);
      },
    );
    test('${theme.brightness.name} semantic text colors meet AA', () {
      final c = theme.colorScheme;
      for (final pair in [
        (c.onPrimary, c.primary, 'primary'),
        (c.onPrimaryContainer, c.primaryContainer, 'primaryContainer'),
        (c.onSecondary, c.secondary, 'secondary'),
        (c.onError, c.error, 'error'),
        (c.onSurface, c.surface, 'surface'),
      ]) {
        final a = pair.$1.computeLuminance();
        final b = pair.$2.computeLuminance();
        final ratio = (math.max(a, b) + .05) / (math.min(a, b) + .05);
        expect(ratio, greaterThanOrEqualTo(4.5), reason: pair.$3);
      }
    });
  }

  testWidgets('empty composer keeps an obvious writing area', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: VnlfTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ComposerEditor(
              document: const {
                'type': 'doc',
                'content': [
                  {'type': 'paragraph'},
                ],
              },
              assets: const {},
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(FleatherEditor)).height,
      greaterThanOrEqualTo(180),
    );
  });

  testWidgets('phone post keeps its primary actions on one row', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: VnlfTheme.light(),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(12),
            child: VnlfPostCard(
              post: presentPost(samplePost),
              upvoteSemanticLabel: 'Ủng hộ',
              bookmarkSemanticLabel: 'Lưu bài viết',
              onVoteChanged: (_) {},
              onCommentTap: () {},
              onShareTap: () {},
              onBookmarkToggle: () {},
            ),
          ),
        ),
      ),
    );
    expect(
      tester.getTopLeft(find.bySemanticsLabel('Ủng hộ')).dy,
      closeTo(tester.getTopLeft(find.bySemanticsLabel('Lưu bài viết')).dy, 1),
    );
  });

  testWidgets('settings preserves the synthetic owner for subsequent panels', (
    tester,
  ) async {
    final container = ProviderContainer(overrides: auditOverrides());
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MainApp()),
    );
    await tester.pumpAndSettle();
    final router =
        tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig!
            as GoRouter;
    router.go('/settings');
    await tester.pumpAndSettle();
    expect(container.read(sessionStateProvider)?.userId, auditOwner.userId);
  });

  testWidgets('discover post actions respond to votes and bookmarks', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: auditOverrides(),
        child: MaterialApp(
          theme: VnlfTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: DiscoverArticles(posts: [samplePost], query: ''),
            ),
          ),
        ),
      ),
    );
    final card = tester.widget<VnlfPostCard>(find.byType(VnlfPostCard));
    expect(card.onVoteChanged, isNotNull);
    expect(card.onBookmarkToggle, isNotNull);
    card.onVoteChanged!(VoteState.upvoted);
    await tester.pumpAndSettle();
    expect(
      tester.widget<VnlfPostCard>(find.byType(VnlfPostCard)).post!.viewerVote,
      VoteState.upvoted,
    );
    tester.widget<VnlfPostCard>(find.byType(VnlfPostCard)).onBookmarkToggle!();
    await tester.pumpAndSettle();
    expect(
      tester.widget<VnlfPostCard>(find.byType(VnlfPostCard)).post!.isBookmarked,
      isTrue,
    );
  });

  testWidgets('invalid composer links show a validation message', (
    tester,
  ) async {
    final controller = FleatherController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ComposerToolbar(controller: controller)),
      ),
    );
    await tester.tap(find.byTooltip('Liên kết'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'http://');
    await tester.tap(find.text('Áp dụng'));
    await tester.pumpAndSettle();
    expect(find.text('Nhập liên kết web hoặc email hợp lệ.'), findsOneWidget);
  });

  testWidgets('post actions have native targets and expose toggle state', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: VnlfTheme.light(),
        home: Scaffold(
          body: VnlfPostInteractionBar(
            voteScore: 12345,
            voteState: VoteState.upvoted,
            commentCount: 12345,
            isBookmarked: true,
            upvoteSemanticLabel: 'Ủng hộ',
            downvoteSemanticLabel: 'Phản đối',
            bookmarkSemanticLabel: 'Lưu bài viết',
            commentSemanticLabel: 'Bình luận',
            shareSemanticLabel: 'Chia sẻ',
            onVoteChanged: (_) {},
            onCommentTap: () {},
            onShareTap: () {},
            onBookmarkToggle: () {},
          ),
        ),
      ),
    );
    for (final label in [
      'Ủng hộ',
      'Phản đối',
      'Lưu bài viết',
      'Bình luận',
      'Chia sẻ',
    ]) {
      final node = tester.getSemantics(
        find.bySemanticsLabel(RegExp('^$label')),
      );
      expect(node.rect.width, greaterThanOrEqualTo(48), reason: label);
      expect(node.rect.height, greaterThanOrEqualTo(48), reason: label);
      if (label == 'Chia sẻ' || label == 'Lưu bài viết') {
        expect(node.rect.width, 48, reason: '$label must not fill a new row');
      }
    }
    expect(
      tester.getSemantics(find.bySemanticsLabel('Ủng hộ')),
      matchesSemantics(
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasToggledState: true,
        isToggled: true,
        label: 'Ủng hộ',
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
      ),
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('phone header controls have native touch targets', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: VnlfTheme.light(),
        home: Scaffold(
          body: VnlfMobileStickyHeader(
            title: 'Bảng tin',
            onBack: () {},
            backTooltip: 'Back',
            composeSemanticLabel: 'Tạo bài đăng',
            searchSemanticLabel: 'Tìm kiếm',
            notificationsSemanticLabel: 'Thông báo',
            onComposeTap: () {},
            onSearchTap: () {},
            onNotificationsTap: (_) {},
          ),
        ),
      ),
    );
    // The website's phone bar: 54px tall, an 18px page title, bare icons.
    expect(tester.getSize(find.byType(VnlfMobileStickyHeader)).height, 54);
    expect(
      tester.widget<Text>(find.text('Bảng tin')).style?.fontSize,
      VnlfTypography.baseSize + 5,
    );
    expect(find.byType(InkWell), findsNWidgets(4));
    for (final control in find.byType(InkWell).evaluate()) {
      final size = tester.getSize(find.byWidget(control.widget));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }
  });

  testWidgets('theme segments can be changed with the keyboard', (
    tester,
  ) async {
    ThemeMode? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 252,
            child: VnlfThemeSegmentPicker(
              themeMode: ThemeMode.system,
              onThemeModeChanged: (mode) => selected = mode,
            ),
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(selected, isNotNull);
  });

  for (final width in [320.0, 900.0, 1440.0]) {
    testWidgets('live voice and account panels fit $width at 200%', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderContainer(overrides: auditOverrides());
      addTearDown(container.dispose);
      for (final surface in auditAuxiliarySurfaces().entries) {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: VnlfTheme.dark(),
              locale: const Locale('vi'),
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              supportedLocales: const [Locale('vi')],
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
              home: Scaffold(body: surface.value),
            ),
          ),
        );
        await tester.pumpAndSettle();
        if (surface.key == 'voice-live') {
          await container
              .read(voiceSessionProvider.notifier)
              .join(auditVoiceRoom);
          await tester.pumpAndSettle();
          expect(find.text('Bạn đọc Linux'), findsOneWidget);
        }
        expect(tester.takeException(), isNull, reason: surface.key);
      }
    });
  }

  testWidgets(
    'code copy does not obscure code and scrolling uses a real thumb',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VnlfTheme.light(),
          home: const Scaffold(
            body: SizedBox(
              width: 300,
              child: VnlfCodeBlock(
                code: 'sudo pacman -Syu && systemctl --user status example.service',
                copyLabel: 'Sao chép',
                copiedLabel: 'Đã sao chép',
              ),
            ),
          ),
        ),
      );
      final copy = find.text('Sao chép');
      final code = find.text(
        'sudo pacman -Syu && systemctl --user status example.service',
      );
      expect(
        tester.getRect(copy).bottom,
        lessThanOrEqualTo(tester.getRect(code).top),
      );
      expect(find.byType(Scrollbar), findsOneWidget);
      final target = find
          .ancestor(of: copy, matching: find.byType(InkWell))
          .first;
      expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
    },
  );

  testWidgets('small phone calendar dates remain readable and tappable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    tester.platformDispatcher.localesTestValue = const [Locale('vi')];
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      ProviderScope(overrides: auditOverrides(), child: const MainApp()),
    );
    await tester.pumpAndSettle();
    final router =
        tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig!
            as GoRouter;
    router.go('/activity');
    await tester.pumpAndSettle();
    final date = find.widgetWithText(OutlinedButton, '1');
    await tester.ensureVisible(date);
    final size = tester.getSize(date);
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone search and chat fit above the keyboard at 200% text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    tester.platformDispatcher.localesTestValue = const [Locale('vi')];
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      ProviderScope(overrides: auditOverrides(), child: const MainApp()),
    );
    await tester.pumpAndSettle();
    final router =
        tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig!
            as GoRouter;
    final failures = <String>[];
    for (final route in [
      '/search',
      '/channels/linux',
      '/messages/audit-dm',
      '/compose',
    ]) {
      router.go(route);
      await tester.pumpAndSettle();
      final error = tester.takeException();
      if (error != null) failures.add('$route: $error');
    }
    expect(failures, isEmpty);
  });

  for (final width in [320.0, 839.0, 840.0, 900.0, 1180.0, 1181.0, 1440.0]) {
    testWidgets('all public routes fit $width at 200% text size', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      tester.platformDispatcher.localesTestValue = const [Locale('vi')];
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await tester.pumpWidget(
        ProviderScope(overrides: auditOverrides(), child: const MainApp()),
      );
      await tester.pumpAndSettle();
      final router =
          tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig!
              as GoRouter;
      final failures = <String>[];
      for (final route in [
        '/',
        '/thread/post-synth-1',
        '/profile/hoangnam',
        '/discover',
        '/search',
        '/leaderboard',
        '/projects',
        '/channels',
        '/messages/audit-dm',
        '/channels/linux',
        '/projects/vnlf-cli',
        '/projects/submit',
        '/voice',
        '/activity',
        '/feedback',
        '/feedback/$auditFeedbackId',
        '/settings',
        '/compose',
      ]) {
        router.go(route);
        await tester.pumpAndSettle();
        final error = tester.takeException();
        if (error != null) failures.add('$route @ $width: $error');
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(failures, isEmpty);
    });
  }
}
