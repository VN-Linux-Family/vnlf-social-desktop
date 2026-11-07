import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../core/api_client.dart';
import 'mention_candidates.dart';

final class MentionToken {
  const MentionToken(this.start, this.query);
  final int start;
  final String query;
}

final _mentionPattern = RegExp(
  r'(?:^|[\s(])@([\p{L}\p{N}_.]*(?: [\p{L}\p{N}_.]+){0,2})$',
  unicode: true,
);

MentionToken? mentionToken(String text, int caret) {
  if (caret < 0 || caret > text.length) return null;
  final match = _mentionPattern.firstMatch(text.substring(0, caret));
  final query = match?.group(1);
  if (query == null || query.length > 30) return null;
  return MentionToken(caret - query.length - 1, query);
}

/// Owns suggestions for one input and one authenticated article context.
/// Dispose it with the input. The caller must provide the current session state.
final class MentionController extends ChangeNotifier {
  MentionController({
    required this.input,
    required this.repository,
    required ApiClient client,
    required String articleId,
    required bool authenticated,
    this.focusNode,
  }) : // Public argument names differ from the private fields.
       // ignore: prefer_initializing_formals
       _articleId = articleId,
       // ignore: prefer_initializing_formals
       _authenticated = authenticated {
    _unsubscribe = client.observeSessionInvalidation(_sessionInvalidated);
    input.addListener(_follow);
    focusNode?.addListener(_focusChanged);
    _follow();
  }
  final TextEditingController input;
  final FocusNode? focusNode;
  final MentionCandidatesRepository repository;
  late final void Function() _unsubscribe;
  String _articleId;
  bool _authenticated;
  Timer? _timer;
  int _generation = 0;
  bool _disposed = false;
  MentionToken? _token;
  String? _dismissed;
  final _cache = <String, (DateTime, List<MentionCandidate>)>{};
  List<MentionCandidate> items = const [];
  Object? error;
  bool loading = false;
  int active = 0;

  String? _key(MentionToken? token) =>
      token == null ? null : '${token.start}:${token.query}';

  void updateContext({required String articleId, required bool authenticated}) {
    if (_articleId == articleId && _authenticated == authenticated) return;
    _articleId = articleId;
    _authenticated = authenticated;
    _reset();
    _follow();
  }

  void _sessionInvalidated() {
    _authenticated = false;
    _reset();
  }

  void _reset() {
    _generation++;
    _timer?.cancel();
    _cache.clear();
    _token = null;
    _dismissed = null;
    items = const [];
    error = null;
    loading = false;
    active = 0;
    notifyListeners();
  }

  void _focusChanged() {
    if (focusNode?.hasFocus == false) {
      dismiss();
    } else {
      _token = null;
      _follow();
    }
  }

  void _follow() {
    final selection = input.selection;
    final token =
        _authenticated &&
            (focusNode?.hasFocus ?? true) &&
            selection.isValid &&
            selection.isCollapsed
        ? mentionToken(input.text, selection.baseOffset)
        : null;
    final oldKey = _key(_token);
    final key = _key(token);
    if (key == oldKey) return;
    _token = token;
    _dismissed = null;
    _generation++;
    final generation = _generation;
    _timer?.cancel();
    items = const [];
    error = null;
    loading = false;
    active = 0;
    notifyListeners();
    if (token == null) return;
    final cached = _cache.remove(token.query);
    if (cached != null &&
        DateTime.now().difference(cached.$1) < const Duration(seconds: 30)) {
      _cache[token.query] = cached;
      items = cached.$2;
      notifyListeners();
      return;
    }
    _timer = Timer(const Duration(milliseconds: 150), () async {
      if (_disposed || generation != _generation) return;
      loading = true;
      notifyListeners();
      try {
        final result = List<MentionCandidate>.unmodifiable(
          (await repository.search(_articleId, token.query)).take(8),
        );
        if (_disposed || generation != _generation) return;
        _cache[token.query] = (DateTime.now(), result);
        while (_cache.length > 32) {
          _cache.remove(_cache.keys.first);
        }
        items = result;
      } catch (failure) {
        if (_disposed || generation != _generation) return;
        error = failure;
      }
      loading = false;
      notifyListeners();
    });
  }

  void dismiss() {
    _dismissed = _key(_token);
    _generation++;
    _timer?.cancel();
    items = const [];
    loading = false;
    error = null;
    notifyListeners();
  }

  void pick(MentionCandidate candidate) {
    final token = _token;
    final caret = input.selection.baseOffset;
    if (!input.value.composing.isCollapsed ||
        !(focusNode?.hasFocus ?? true) ||
        token == null ||
        _dismissed == _key(token) ||
        !items.contains(candidate) ||
        caret < token.start ||
        caret > input.text.length) {
      return;
    }
    final insert = '@${candidate.username} ';
    final text = input.text.replaceRange(token.start, caret, insert);
    final position = token.start + insert.length;
    input.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: position),
    );
    dismiss();
  }

  /// Returns true when the input should not handle this key itself.
  bool handleKey(KeyEvent event) {
    if (event is! KeyDownEvent ||
        items.isEmpty ||
        !input.value.composing.isCollapsed) {
      return false;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
        event.logicalKey == LogicalKeyboardKey.arrowUp) {
      active =
          (active +
              (event.logicalKey == LogicalKeyboardKey.arrowDown
                  ? 1
                  : items.length - 1)) %
          items.length;
      notifyListeners();
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      dismiss();
      return true;
    }
    if ((event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.tab) &&
        !HardwareKeyboard.instance.isShiftPressed) {
      pick(items[active]);
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _timer?.cancel();
    _unsubscribe();
    input.removeListener(_follow);
    focusNode?.removeListener(_focusChanged);
    super.dispose();
  }
}
