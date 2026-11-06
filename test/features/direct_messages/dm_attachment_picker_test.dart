import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/l10n/app_localizations.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/design_system/design_system.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/direct_messages/domain/direct_message_models.dart';
import 'package:vnlfsocialapp/src/features/direct_messages/presentation/direct_message_state.dart';
import 'package:vnlfsocialapp/src/features/direct_messages/presentation/direct_message_composer.dart';
import 'package:vnlfsocialapp/src/features/direct_messages/presentation/dm_attachment_picker.dart';

import 'direct_message_controller_test.dart' show ControlledDmRepository;

void main() {
  testWidgets(
    'selected image is streamed through the upload pipeline and draft is retained',
    (tester) async {
      final repo = _Uploads();
      await _pump(tester, repo, () async => [_file]);
      await tester.enterText(
        find.byKey(const Key('dm-chat-input')),
        'Tiếng Việt: ặ ữ ờ ẫ ệ',
      );
      await tester.tap(find.byKey(const Key('dm-attach-button')));
      await tester.pumpAndSettle();
      expect(repo.uploads, ['anh-thu.png']);
      expect(repo.bytes, [1, 2, 3]);
      expect(find.text('anh-thu.png'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('dm-chat-input')))
            .controller!
            .text,
        'Tiếng Việt: ặ ữ ờ ẫ ệ',
      );
    },
  );
  testWidgets(
    'an image picker opened by a previous account cannot upload under the next account',
    (tester) async {
      final repo = _Uploads();
      final pick = Completer<List<DmUploadFile>>();
      final container = await _pump(tester, repo, () => pick.future);
      await tester.tap(find.byKey(const Key('dm-attach-button')));
      await tester.pump();
      container.read(sessionStateProvider.notifier).state = const Session(
        userId: 'second',
        displayName: 'Hai',
      );
      await tester.pump();
      pick.complete([_file]);
      await tester.pumpAndSettle();
      expect(repo.uploads, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'more than four selected files are rejected with visible feedback before uploading',
    (tester) async {
      final repo = _Uploads();
      await _pump(tester, repo, () async => List.filled(5, _file));
      await tester.tap(find.byKey(const Key('dm-attach-button')));
      await tester.pumpAndSettle();
      expect(repo.uploads, isEmpty);
      expect(find.byKey(const Key('dm-picker-error')), findsOneWidget);
    },
  );
}

final _file = DmUploadFile(
  name: 'anh-thu.png',
  mime: 'image/png',
  length: 3,
  openRead: () => Stream.value([1, 2, 3]),
);

class _Uploads extends ControlledDmRepository {
  final uploads = <String>[];
  final bytes = <int>[];
  @override
  Future<DmUploadedAsset> uploadAttachment(DmUploadFile file) async {
    uploads.add(file.name);
    await for (final chunk in file.openRead()) {
      bytes.addAll(chunk);
    }
    return DmUploadedAsset(
      assetId: 'asset-1',
      status: 'READY',
      mime: file.mime,
      size: file.length,
    );
  }
}

Future<ProviderContainer> _pump(
  WidgetTester tester,
  _Uploads repo,
  DmAttachmentPicker picker,
) async {
  final container = ProviderContainer(
    overrides: [
      directMessageRepositoryProvider.overrideWithValue(repo),
      dmAttachmentPickerProvider.overrideWithValue(picker),
      sessionStateProvider.overrideWith(
        (ref) => const Session(userId: 'test-user', displayName: 'Một'),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: VnlfTheme.light(),
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: DirectMessageComposer(conversationId: 'conv-1'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}
