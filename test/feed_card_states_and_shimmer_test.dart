import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/design_system/design_system.dart';

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

  Future<void> pumpWithMediaQuery(
    WidgetTester tester,
    Widget child, {
    bool disableAnimations = false,
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: VnlfTheme.light(),
        darkTheme: VnlfTheme.dark(),
        themeMode: themeMode,
        builder: (context, appChild) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(disableAnimations: disableAnimations),
          child: appChild!,
        ),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
  }

  List<BoxDecoration> collectBoneDecorations(WidgetTester tester) {
    return tester
        .widgetList<AnimatedContainer>(
          find.descendant(
            of: find.byType(VnlfSkeletonBox),
            matching: find.byType(AnimatedContainer),
          ),
        )
        .map((container) => container.decoration! as BoxDecoration)
        .toList();
  }

  testWidgets('shared AnimationController drives list shimmer across all rows', (
    tester,
  ) async {
    final controller = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(milliseconds: 1200),
      value: 0.1,
    );
    addTearDown(controller.dispose);

    await pumpWithMediaQuery(
      tester,
      VnlfFeedSkeletonList(
        itemCount: 3,
        controller: controller,
        semanticLabel: 'Đang tải danh sách bài viết bảng tin',
        itemSemanticLabel: 'Đang tải bài viết',
      ),
    );

    final rows = tester
        .widgetList<VnlfPostCardSkeleton>(find.byType(VnlfPostCardSkeleton))
        .toList();
    expect(rows, hasLength(3));
    for (final row in rows) {
      expect(identical(row.controller, controller), isTrue);
    }

    final decorationsAtStart = collectBoneDecorations(tester);
    expect(decorationsAtStart, isNotEmpty);
    for (final decoration in decorationsAtStart) {
      expect(decoration.gradient, isA<LinearGradient>());
    }
    final initialGradient =
        decorationsAtStart.first.gradient! as LinearGradient;
    final lastRowInitialGradient =
        decorationsAtStart.last.gradient! as LinearGradient;
    expect(initialGradient.begin, equals(lastRowInitialGradient.begin));

    // Advance the single shared controller and verify all rows update together.
    controller.value = 0.75;
    await tester.pump();

    final decorationsAfterStep = collectBoneDecorations(tester);
    final updatedGradient =
        decorationsAfterStep.first.gradient! as LinearGradient;
    final lastRowUpdatedGradient =
        decorationsAfterStep.last.gradient! as LinearGradient;
    expect(updatedGradient.begin, isNot(equals(initialGradient.begin)));
    expect(updatedGradient.begin, equals(lastRowUpdatedGradient.begin));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'reduce-motion disables shimmer animation and collapses bones to static',
    (tester) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 1200),
        value: 0.25,
      );
      addTearDown(controller.dispose);

      await pumpWithMediaQuery(
        tester,
        VnlfFeedSkeletonList(
          itemCount: 2,
          controller: controller,
          semanticLabel: 'Đang tải danh sách bài viết bảng tin',
        ),
        disableAnimations: true,
      );

      final containers = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .toList();
      expect(containers, isNotEmpty);
      expect(
        containers.every((container) => container.duration == Duration.zero),
        isTrue,
      );

      final decorations = collectBoneDecorations(tester);
      expect(decorations, isNotEmpty);
      for (final decoration in decorations) {
        expect(decoration.gradient, isNull);
        expect(decoration.color, equals(VnlfColors.light.surfaceSoft));
      }

      // Updating controller value under reduce-motion keeps static bone shapes.
      controller.value = 0.85;
      await tester.pump();

      for (final decoration in collectBoneDecorations(tester)) {
        expect(decoration.gradient, isNull);
        expect(decoration.color, equals(VnlfColors.light.surfaceSoft));
      }
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'VnlfPostCard loading, empty, and error state variants render constructor parameters',
    (tester) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 1200),
        value: 0.4,
      );
      addTearDown(controller.dispose);

      var emptyActionCount = 0;
      var errorRetryCount = 0;

      await pumpWithMediaQuery(
        tester,
        Column(
          children: [
            VnlfPostCard(
              isLoading: true,
              shimmerController: controller,
              showSkeletonTitle: true,
              showSkeletonAttachment: true,
              loadingSemanticLabel: 'Đang tải bài viết — Tiếng Việt: ặ ữ ờ ẫ ệ',
            ),
            VnlfPostCard(
              isEmpty: true,
              emptyTitle: 'Chưa có bài viết nào — Tiếng Việt: ặ ữ ờ ẫ ệ',
              emptyMessage:
                  'Bảng tin hiện chưa có bài viết trong mục này. Hãy làm mới.',
              emptyActionLabel: 'Làm mới danh sách',
              onEmptyAction: () => emptyActionCount++,
              emptySemanticLabel: 'Trạng thái bảng tin trống',
            ),
            VnlfPostCard(
              errorTitle: 'Không thể tải bài viết — Tiếng Việt: ặ ữ ờ ẫ ệ',
              errorMessage:
                  'Đã xảy ra sự cố kết nối khi tải bài viết. Vui lòng thử lại.',
              retryLabel: 'Thử lại ngay',
              onRetry: () => errorRetryCount++,
              errorSemanticLabel: 'Trạng thái lỗi bài viết',
            ),
          ],
        ),
      );

      // 1. Loading variant renders VnlfPostCardSkeleton driven by controller.
      expect(find.byType(VnlfPostCardSkeleton), findsOneWidget);
      final skeleton = tester.widget<VnlfPostCardSkeleton>(
        find.byType(VnlfPostCardSkeleton),
      );
      expect(identical(skeleton.controller, controller), isTrue);
      expect(skeleton.showTitle, isTrue);
      expect(skeleton.showAttachment, isTrue);
      expect(
        skeleton.semanticLabel,
        'Đang tải bài viết — Tiếng Việt: ặ ữ ờ ẫ ệ',
      );

      // 2. Empty variant renders VnlfFeedEmptyState with passed constructor copy.
      expect(find.byType(VnlfFeedEmptyState), findsOneWidget);
      expect(
        find.text('Chưa có bài viết nào — Tiếng Việt: ặ ữ ờ ẫ ệ'),
        findsOneWidget,
      );
      expect(
        find.text('Bảng tin hiện chưa có bài viết trong mục này. Hãy làm mới.'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Làm mới danh sách'));
      await tester.tap(find.text('Làm mới danh sách'));
      await tester.pump();
      expect(emptyActionCount, 1);

      // 3. Error variant renders VnlfFeedErrorState with passed constructor copy.
      expect(find.byType(VnlfFeedErrorState), findsOneWidget);
      expect(
        find.text('Không thể tải bài viết — Tiếng Việt: ặ ữ ờ ẫ ệ'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Đã xảy ra sự cố kết nối khi tải bài viết. Vui lòng thử lại.',
        ),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Thử lại ngay'));
      await tester.tap(find.text('Thử lại ngay'));
      await tester.pump();
      expect(errorRetryCount, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
