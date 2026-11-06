import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/features/realtime/domain/latest_history_window.dart';

void main() {
  final one = (id: 'a', at: DateTime.utc(2026, 1, 1));
  final deleted = (id: 'b', at: DateTime.utc(2026, 1, 2));
  final live = (id: 'c', at: DateTime.utc(2026, 1, 3));
  test(
    'latest-page catch-up drops missed deletions while preserving older pages',
    () {
      expect(
        latestHistoryWindow(
          current: [one, deleted, live],
          incoming: [live],
          hasOlder: true,
          idOf: (m) => m.id,
          createdAt: (m) => m.at,
        ),
        [one, deleted, live],
      );
      expect(
        latestHistoryWindow(
          current: [one, deleted, live],
          incoming: [one, live],
          hasOlder: true,
          idOf: (m) => m.id,
          createdAt: (m) => m.at,
        ),
        [one, live],
      );
    },
  );
  test(
    'a complete latest history is authoritative including an empty history',
    () {
      expect(
        latestHistoryWindow(
          current: [one, deleted],
          incoming: [one],
          hasOlder: false,
          idOf: (m) => m.id,
          createdAt: (m) => m.at,
        ),
        [one],
      );
      expect(
        latestHistoryWindow(
          current: [one],
          incoming: <({String id, DateTime at})>[],
          hasOlder: false,
          idOf: (m) => m.id,
          createdAt: (m) => m.at,
        ),
        isEmpty,
      );
    },
  );
}
