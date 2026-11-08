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
          title: 'Xếp hạng tuần',
          viewAllLabel: 'Xem tất cả ↗',
          footerCopyright: 'VNLF Social · 2026',
          communityRulesLabel: 'Quy chuẩn cộng đồng',
          privacyLabel: 'Riêng tư',
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
                  VnlfPostCardSkeleton(
                    showTitle: true,
                    showAttachment: true,
                    semanticLabel: 'Đang tải bài viết',
                  ),
                  SizedBox(height: 12),
                  VnlfFeedSkeletonList(
                    itemCount: 1,
                    semanticLabel: 'Đang tải danh sách bài viết bảng tin',
                    itemSemanticLabel: 'Đang tải bài viết',
                  ),
                  SizedBox(height: 12),
                  VnlfLeaderboardRowSkeleton(),
                  SizedBox(height: 12),
                  VnlfLeaderboardCardSkeleton(
                    itemCount: 1,
                    title: 'Xếp hạng tuần',
                    footerCopyright: 'VNLF Social · 2026',
                    communityRulesLabel: 'Quy chuẩn cộng đồng',
                    privacyLabel: 'Riêng tư',
                    semanticLabel: 'Đang tải bảng xếp hạng tuần',
                  ),
                  SizedBox(height: 12),
                  VnlfStateCard(
                    icon: Icons.info_outline,
                    title: 'Tiếng Việt: ặ ữ ờ ẫ ệ — trạng thái nội dung',
                    message: 'Thông tin này cần xuống dòng tự nhiên ở cỡ chữ lớn để người dùng dễ đọc.',
                    actionLabel: 'Thử lại với cỡ chữ lớn',
                    onAction: _noop,
                  ),
                  SizedBox(height: 12),
                  VnlfFeedEmptyState(
                    title: 'Chưa có bài viết nào',
                    message: 'Bảng tin hiện chưa có bài viết trong mục này. Hãy thử chuyển sang mục khác hoặc làm mới.',
                    actionLabel: 'Làm mới',
                    semanticLabel: 'Bảng tin trống: Chưa có bài viết nào',
                  ),
                  SizedBox(height: 12),
                  VnlfFeedErrorState(
                    title: 'Không thể tải bảng tin',
                    message: 'Đã xảy ra sự cố khi tải danh sách bài viết. Vui lòng kiểm tra kết nối và thử lại.',
                    retryLabel: 'Thử lại',
                    semanticLabel: 'Lỗi bảng tin: Không thể tải bảng tin',
                  ),
                  SizedBox(height: 12),
                  VnlfLeaderboardEmptyState(
                    headerTitle: 'Xếp hạng tuần',
                    title: 'Chưa có dữ liệu xếp hạng',
                    message: 'Bảng xếp hạng tuần này đang được cập nhật.',
                    actionLabel: 'Làm mới',
                    semanticLabel:
                        'Bảng xếp hạng tuần trống: Chưa có dữ liệu xếp hạng',
                  ),
                  SizedBox(height: 12),
                  VnlfLeaderboardErrorState(
                    headerTitle: 'Xếp hạng tuần',
                    title: 'Không thể tải bảng xếp hạng',
                    message: 'Đã xảy ra sự cố khi tải dữ liệu xếp hạng tuần.',
                    retryLabel: 'Thử lại',
                    semanticLabel:
                        'Lỗi bảng xếp hạng tuần: Không thể tải bảng xếp hạng',
                  ),
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
