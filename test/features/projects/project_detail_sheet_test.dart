import 'package:vnlfsocialapp/src/features/projects/domain/project_directory.dart';
import 'package:vnlfsocialapp/src/features/projects/presentation/project_directory_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/design_system/design_system.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/projects/presentation/projects_screen.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      'project accent and neutral surfaces render in ${dark ? 'dark' : 'light'} mode',
      (tester) async {
        await _openProject(tester, dark: dark, accent: '#2563EB');

        final sheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
        expect(sheet.backgroundColor, Color(dark ? 0xff141715 : 0xffffffff));
        final button = tester.widget<FilledButton>(find.byType(FilledButton));
        final background = button.style!.backgroundColor!.resolve({})!;
        final foreground = button.style!.foregroundColor!.resolve({})!;
        expect(background, const Color(0xff2563eb));
        expect(_contrast(background, foreground), greaterThanOrEqualTo(4.5));

        final stats = tester.widget<Container>(
          find
              .ancestor(of: find.text('Sao'), matching: find.byType(Container))
              .first,
        );
        expect(
          (stats.decoration! as BoxDecoration).color,
          Color(dark ? 0xff1b1f1c : 0xfff1f3f1),
        );
        final star = tester.widget<Icon>(find.byIcon(Icons.star_rounded));
        expect(star.color, Color(dark ? 0xfff2c14e : 0xffd99a06));
        final forks = tester.widget<Icon>(find.byIcon(Icons.alt_route_rounded));
        expect(forks.color, const Color(0xff2563eb));
        final rating = tester.widget<Icon>(
          find.byIcon(Icons.recommend_rounded),
        );
        expect(rating.color, const Color(0xff2563eb));
        expect(tester.takeException(), isNull);
      },
    );

    for (final accent in ['#fff', '#101010', 'invalid', null]) {
      testWidgets(
        'accent $accent stays readable in ${dark ? 'dark' : 'light'} mode',
        (tester) async {
          await _openProject(tester, dark: dark, accent: accent);

          final button = tester.widget<FilledButton>(find.byType(FilledButton));
          final background = button.style!.backgroundColor!.resolve({})!;
          final foreground = button.style!.foregroundColor!.resolve({})!;
          expect(background, switch (accent) {
            '#fff' => Colors.white,
            '#101010' => const Color(0xff101010),
            _ => Color(dark ? 0xff7fcf9a : 0xff1d6b43),
          });
          expect(_contrast(background, foreground), greaterThanOrEqualTo(4.5));
          final label = tester.widget<Text>(
            find.text('Mở kho mã nguồn (GitHub)'),
          );
          expect(
            _contrast(background, label.style!.color!),
            greaterThanOrEqualTo(4.5),
          );

          final icon = tester.widget<Icon>(
            find.byIcon(Icons.folder_special_rounded),
          );
          final badge = tester.widget<Container>(
            find
                .ancestor(
                  of: find.byIcon(Icons.folder_special_rounded),
                  matching: find.byType(Container),
                )
                .first,
          );
          expect(
            _contrast(icon.color!, (badge.decoration! as BoxDecoration).color!),
            greaterThanOrEqualTo(3),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('small sheet scrolls at 200% text size and closes', (
    tester,
  ) async {
    await _openProject(
      tester,
      size: const Size(320, 568),
      textScale: 2,
      longContent: true,
    );
    expect(tester.takeException(), isNull);
    final action = find.text('Mở kho mã nguồn (GitHub)');
    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    expect(action.hitTestable(), findsOneWidget);
    expect(find.text('Ngôn ngữ'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final close = find.byTooltip('Đóng');
    await tester.ensureVisible(close);
    await tester.pumpAndSettle();
    await tester.tap(close);
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _openProject(
  WidgetTester tester, {
  bool dark = false,
  String? accent,
  Size size = const Size(390, 844),
  double textScale = 1,
  bool longContent = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final item = ProjectItem(
    id: 'project-synthetic',
    name: 'vnlf-cli',
    tagline: longContent
        ? List.filled(
            12,
            'Tiếng Việt: ặ ữ ờ ẫ ệ. Công cụ cộng đồng Linux.',
          ).join(' ')
        : 'Tiếng Việt: ặ ữ ờ ẫ ệ',
    type: 'tool',
    accentColor: accent,
    repo: {
      'provider': 'github',
      'owner': 'synthetic-community',
      'name': 'vnlf-cli',
      'url': 'https://github.com/synthetic-community/vnlf-cli',
      'stars': 128,
      'forks': 24,
      'language': longContent ? 'JavaScript' : 'Dart',
    },
    rating: const {'average': 4.9, 'count': 35},
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        projectDirectoryRepositoryProvider.overrideWithValue(
          _DetailProjectRepository(item),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('vi')],
        theme: dark ? VnlfTheme.dark() : VnlfTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const Scaffold(body: ProjectsScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byType(VnlfProjectPreviewCard));
  await tester.pumpAndSettle();
}

double _contrast(Color a, Color b) {
  final first = a.computeLuminance();
  final second = b.computeLuminance();
  return first > second
      ? (first + 0.05) / (second + 0.05)
      : (second + 0.05) / (first + 0.05);
}

class _DetailProjectRepository implements ProjectDirectoryRepository {
  _DetailProjectRepository(this.item);
  final ProjectItem item;
  @override
  Future<ProjectDirectoryPage> fetch(
    ProjectFilters filters, {
    String? cursor,
    bool refresh = false,
  }) async => ProjectDirectoryPage(
    page: ProjectsPage(items: [item]),
    types: const [],
    languages: const [],
  );
}
