import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/design_system/design_system.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader('BeVietnamPro');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      loader.addFont(rootBundle.load('assets/fonts/BeVietnamPro-$weight.ttf'));
    }
    await loader.load();
  });

  Future<void> pumpAtViewport(
    WidgetTester tester,
    Widget child,
    Size size, {
    double textScale = 2,
    bool disableAnimations = true,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: VnlfTheme.light(),
        builder: (context, appChild) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: disableAnimations,
          ),
          child: appChild!,
        ),
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('304px leaderboard wraps labels at 200% text scale', (
    tester,
  ) async {
    const username = 'linux_member';
    const displayName = 'Nguyễn Minh Khôi của Cộng đồng Linux';
    const author = AuthorData(
      id: 'fixture-author-1',
      username: username,
      displayName: displayName,
      style: AuthorStyleData(distroBadge: DistroBadgeType.arch),
    );

    await pumpAtViewport(
      tester,
      const SizedBox(
        width: 304,
        child: VnlfLeaderboardCard(
          width: 304,
          entries: [LeaderboardEntryData(rank: 1, author: author, points: 88)],
        ),
      ),
      const Size(1440, 1000),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Xếp hạng tuần'), findsOneWidget);
    expect(find.text('Xem tất cả ↗'), findsOneWidget);

    final titleTop = tester.getTopLeft(find.text('Xếp hạng tuần')).dy;
    final linkTop = tester.getTopLeft(find.text('Xem tất cả ↗')).dy;
    expect(linkTop, greaterThan(titleTop));

    final displayNameHeight = tester.getSize(find.text(displayName)).height;
    expect(displayNameHeight, greaterThan(40));

    final communityLabelTop = tester
        .getTopLeft(find.text('Quy chuẩn cộng đồng'))
        .dy;
    final privacyLabelTop = tester.getTopLeft(find.text('Riêng tư')).dy;
    expect(privacyLabelTop, greaterThan(communityLabelTop));
    expect(tester.takeException(), isNull);
  });

  for (final width in [360.0, 1440.0]) {
    testWidgets(
      'skeleton and state cards fit ${width.toInt()}px at 200% scale with reduce motion',
      (tester) async {
        await pumpAtViewport(
          tester,
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  VnlfSkeletonBox(width: 180),
                  SizedBox(height: 12),
                  VnlfPostCardSkeleton(showTitle: true, showAttachment: true),
                  SizedBox(height: 12),
                  VnlfFeedSkeletonList(itemCount: 1),
                  SizedBox(height: 12),
                  VnlfLeaderboardRowSkeleton(),
                  SizedBox(height: 12),
                  VnlfLeaderboardCardSkeleton(itemCount: 1),
                  SizedBox(height: 12),
                  VnlfStateCard(
                    icon: Icons.info_outline,
                    title: 'Tiếng Việt: ặ ữ ờ ẫ ệ — trạng thái nội dung',
                    message: 'Thông tin này cần xuống dòng tự nhiên ở cỡ chữ lớn để người dùng dễ đọc.',
                    actionLabel: 'Thử lại với cỡ chữ lớn',
                    onAction: _noop,
                  ),
                  SizedBox(height: 12),
                  VnlfFeedEmptyState(),
                  SizedBox(height: 12),
                  VnlfFeedErrorState(),
                  SizedBox(height: 12),
                  VnlfLeaderboardEmptyState(),
                  SizedBox(height: 12),
                  VnlfLeaderboardErrorState(),
                ],
              ),
            ),
          ),
          Size(width, 1000),
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(VnlfPostCardSkeleton), findsWidgets);
        expect(find.byType(VnlfLeaderboardCardSkeleton), findsOneWidget);
        expect(find.byType(VnlfStateCard), findsWidgets);
        expect(
          tester
              .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
              .every((container) => container.duration == Duration.zero),
          isTrue,
        );
        expect(tester.binding.transientCallbackCount, 0);
      },
    );

    testWidgets(
      'skeleton size changes do not start an animation at ${width.toInt()}px with reduce motion',
      (tester) async {
        var boxWidth = 48.0;
        late StateSetter updateBox;

        await pumpAtViewport(
          tester,
          StatefulBuilder(
            builder: (context, setState) {
              updateBox = setState;
              return VnlfSkeletonBox(width: boxWidth);
            },
          ),
          Size(width, 600),
        );

        updateBox(() => boxWidth = 96);
        await tester.pump();

        final animatedBox = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer),
        );
        expect(animatedBox.duration, Duration.zero);
        expect(tester.binding.transientCallbackCount, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

void _noop() {}
