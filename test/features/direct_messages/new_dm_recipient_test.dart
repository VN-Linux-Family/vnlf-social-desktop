import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/direct_messages/presentation/direct_message_panels.dart';
import 'package:vnlfsocialapp/src/features/direct_messages/presentation/direct_message_state.dart';
import 'package:vnlfsocialapp/src/features/direct_messages/domain/direct_message_models.dart';
import 'package:vnlfsocialapp/src/features/search/domain/search_results.dart';
import 'package:vnlfsocialapp/src/features/search/presentation/search_providers.dart';

import 'direct_message_controller_test.dart' show ControlledDmRepository;

void main() {
  testWidgets(
    'new DM searches named members and sends their ID only after selection',
    (tester) async {
      final repo = _Recipients();
      final search = _Search();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionStateProvider.overrideWith(
              (ref) => const Session(userId: 'self', displayName: 'Bạn'),
            ),
            directMessageRepositoryProvider.overrideWithValue(repo),
            searchRepositoryProvider.overrideWithValue(search),
          ],
          child: MaterialApp(
            locale: const Locale('vi'),
            supportedLocales: const [Locale('vi')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) => TextButton(
                  onPressed: () => showNewDmDialog(context, ref),
                  child: const Text('Bắt đầu'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Bắt đầu'));
      await tester.pumpAndSettle();
      final input = find.byKey(const Key('dm-member-search'));
      expect(input, findsOneWidget);
      await tester.enterText(input, 'li');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(search.calls, ['li']);
      expect(find.text('Linux thử nghiệm'), findsOneWidget);
      expect(find.text('@linux_test'), findsOneWidget);
      expect(find.text('internal-peer-id'), findsNothing);
      expect(find.text('Tài khoản hiện tại'), findsNothing);
      expect(repo.recipient, isNull);
      await tester.enterText(input, 'linux');
      await tester.pump();
      expect(find.text('Linux thử nghiệm'), findsNothing);
      expect(search.calls, ['li']);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(search.calls, ['li', 'linux']);
      await tester.tap(find.text('Linux thử nghiệm'));
      await tester.pumpAndSettle();
      expect(repo.recipient, 'internal-peer-id');
      expect(tester.takeException(), isNull);
    },
  );
}

class _Search implements SearchRepository {
  final calls = <String>[];
  @override
  Future<SearchResults> search(String query) async {
    calls.add(query);
    return SearchResults(
      users: const [
        Author(id: 'self', username: 'self', displayName: 'Tài khoản hiện tại'),
        Author(
          id: 'internal-peer-id',
          username: 'linux_test',
          displayName: 'Linux thử nghiệm',
        ),
      ],
    );
  }

  @override
  Future<List<SearchTopic>> popularTopics() async => [];
}

class _Recipients extends ControlledDmRepository {
  String? recipient;
  @override
  Future<DmConversationOpenResult> openOrRequestConversation(
    String recipientUserId,
  ) async {
    recipient = recipientUserId;
    return super.openOrRequestConversation(recipientUserId);
  }
}
