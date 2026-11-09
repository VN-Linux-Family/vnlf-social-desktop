import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/utf16_length_formatter.dart';
import '../../../design_system/design_system.dart';
import '../../../i18n/vi.dart';
import '../domain/poll_models.dart';
import 'poll_feedback.dart';
import 'poll_state.dart';

class PollEditDialog extends ConsumerStatefulWidget {
  const PollEditDialog({super.key, required this.poll, required this.authorId});
  final Poll poll;
  final String authorId;
  @override
  ConsumerState<PollEditDialog> createState() => _PollEditDialogState();
}

class _PollEditDialogState extends ConsumerState<PollEditDialog> {
  late final _question = TextEditingController(text: widget.poll.question);
  late final _options = [
    for (final option in widget.poll.options)
      TextEditingController(text: option.label),
  ];
  String? _validation;
  @override
  void dispose() {
    _question.dispose();
    for (final option in _options) {
      option.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final owner = ref.read(sessionStateProvider)?.userId;
    if (owner == null || owner != widget.authorId) return;
    final input = PollInput.tryCreate(
      _question.text,
      _options.map((option) => option.text).toList(),
    );
    if (input == null) {
      setState(() => _validation = vi.app.polls.canCauHoiVa);
      return;
    }
    setState(() => _validation = null);
    final saved = await ref
        .read(pollStoreProvider.notifier)
        .edit(widget.poll, input);
    if (mounted && saved && ref.read(sessionStateProvider)?.userId == owner) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    ref.listen(sessionStateProvider.select((session) => session?.userId), (
      before,
      after,
    ) {
      if (after != widget.authorId && mounted) {
        Navigator.pop(context);
      }
    });
    final state = ref.watch(
      pollStoreProvider.select((state) => state[widget.poll.id]),
    );
    final pending = state?.pending ?? false;
    final locked = (state?.poll ?? widget.poll).totalVotes > 0;
    return AlertDialog(
      title: Text(vi.poll.suaBinhChon),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                vi.app.polls.chiSuaDuocKhi,
                style: VnlfTypography.meta(colors.muted),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('poll-edit-question'),
                controller: _question,
                enabled: !pending && !locked,
                style: VnlfTypography.body(colors.ink),
                maxLength: PollInput.questionLimit,
                buildCounter: _counter(
                  _question,
                  PollInput.questionLimit,
                  colors.muted,
                ),
                inputFormatters: [
                  Utf16LengthFormatter(PollInput.questionLimit),
                ],
                decoration: InputDecoration(labelText: vi.poll.cauHoi),
              ),
              for (var i = 0; i < _options.length; i++)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        key: ValueKey('poll-edit-option-$i'),
                        controller: _options[i],
                        enabled: !pending && !locked,
                        style: VnlfTypography.body(colors.ink),
                        maxLength: PollInput.optionLimit,
                        buildCounter: _counter(
                          _options[i],
                          PollInput.optionLimit,
                          colors.muted,
                        ),
                        inputFormatters: [
                          Utf16LengthFormatter(PollInput.optionLimit),
                        ],
                        decoration: InputDecoration(
                          labelText: format(vi.poll.luaChonSo, {
                            'value': i + 1,
                          }),
                        ),
                      ),
                    ),
                    if (_options.length > PollInput.minOptions)
                      IconButton(
                        key: ValueKey('poll-edit-remove-$i'),
                        tooltip: format(vi.poll.boLuaChon, {'value': i + 1}),
                        onPressed: pending || locked
                            ? null
                            : () {
                                setState(() {
                                  _options.removeAt(i).dispose();
                                });
                              },
                        icon: const Icon(Icons.close, size: 18),
                      ),
                  ],
                ),
              if (_options.length < PollInput.maxOptions)
                TextButton.icon(
                  key: const Key('poll-edit-add'),
                  onPressed: pending || locked
                      ? null
                      : () => setState(
                          () => _options.add(TextEditingController()),
                        ),
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(vi.poll.themLuaChon),
                ),
              if (_validation != null)
                Text(
                  _validation!,
                  key: const Key('poll-edit-validation'),
                  style: VnlfTypography.meta(colors.red),
                ),
              if (locked)
                Text(
                  vi.app.polls.binhChonDaCo,
                  style: VnlfTypography.meta(colors.red),
                ),
              if (state?.failure case final failure?)
                Text(
                  pollFailureText(context, failure),
                  style: VnlfTypography.meta(colors.red),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(vi.common.huy),
        ),
        FilledButton(
          key: const Key('poll-edit-save'),
          onPressed: pending || locked ? null : _save,
          child: Text(pending ? vi.common.dangLuu : vi.common.luu),
        ),
      ],
    );
  }
}

InputCounterWidgetBuilder _counter(
  TextEditingController controller,
  int limit,
  Color color,
) =>
    (
      context, {
      required int currentLength,
      required bool isFocused,
      required int? maxLength,
    }) => Text(
      '${controller.text.length}/$limit',
      style: VnlfTypography.meta(color),
    );
