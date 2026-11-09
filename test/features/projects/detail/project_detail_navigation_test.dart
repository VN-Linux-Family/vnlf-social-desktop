import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/app/app_router.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/design_system/design_system.dart';
import 'package:vnlfsocialapp/src/design_system/components/vnlf_rich_content.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/projects/domain/project_directory.dart';
import 'package:vnlfsocialapp/src/features/projects/presentation/project_directory_controller.dart';
import 'package:vnlfsocialapp/src/features/projects/detail/data/project_detail_repository.dart';
import 'package:vnlfsocialapp/src/features/projects/detail/domain/project_detail.dart';
import 'package:vnlfsocialapp/src/features/projects/detail/presentation/project_detail_screen.dart';

import 'project_detail_test.dart' show fixture;

void main() {
  testWidgets(
    'opening a project loads its detail and native formatted introduction',
    (t) async {
      final router = createMainRouter()..go('/projects');
      addTearDown(router.dispose);
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            ioTransportProvider.overrideWithValue(null),
            projectDirectoryRepositoryProvider.overrideWithValue(_Directory()),
            projectDetailRepositoryProvider.overrideWithValue(_Detail()),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('vi'),
            supportedLocales: const [Locale('vi')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: VnlfTheme.light(),
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.tap(find.byType(VnlfProjectPreviewCard));
      await t.pumpAndSettle();
      expect(find.byType(ProjectDetailScreen), findsOneWidget);
      expect(
        t
            .widget<VnlfAdaptiveShell>(find.byType(VnlfAdaptiveShell))
            .activeDestination,
        VnlfNavDestination.projects,
      );
      final rich = t.widget<VnlfRichContent>(find.byType(VnlfRichContent));
      expect(rich.document.toString(), contains('bold'));
      expect(find.text('Mở bài thảo luận'), findsOneWidget);
    },
  );
}

class _Directory implements ProjectDirectoryRepository {
  @override
  Future<ProjectDirectoryPage> fetch(
    ProjectFilters filters, {
    String? cursor,
    bool refresh = false,
  }) async => ProjectDirectoryPage(
    page: ProjectsPage(
      items: const [ProjectItem(id: 'id', name: 'Dự án', slug: 'du-an')],
    ),
    types: const [],
    languages: const [],
  );
}

class _Detail implements ProjectDetailRepository {
  @override
  Future<ProjectDetail> fetch(String slug, {bool refresh = false}) async =>
      ProjectDetailDto(
        fixture('Dự án')
          ..['intro'] = 'Văn bản **quan trọng**'
          ..['media'] = <Object?>[],
      ).toDomain();
}
