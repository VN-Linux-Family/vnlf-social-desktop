import 'package:flutter/material.dart';

import '../../polls/domain/poll_models.dart';
import '../domain/composer_draft.dart';
import '../domain/composer_poll.dart';
import 'composer_metadata.dart';

class ComposerPollEditor extends StatelessWidget {
  const ComposerPollEditor({
    super.key,
    required this.draft,
    required this.onChanged,
    this.disabled = false,
  });
  final ComposerDraft draft;
  final ValueChanged<ComposerDraft> onChanged;
  final bool disabled;
  @override
  Widget build(BuildContext context) {
    if (draft.format != 'POST') return const SizedBox.shrink();
    final en = Localizations.localeOf(context).languageCode == 'en';
    final published = draft.publishedAt != null || draft.status == 'PUBLISHED';
    final locked = disabled || published;
    final input = draft.pollDraft;
    void change(ComposerPollDraft? value) =>
        onChanged(draft.copyWith(pollDraft: value, pollChanged: true));
    if (input == null) {
      return published
          ? const SizedBox.shrink()
          : Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('composer-add-poll'),
                onPressed: disabled
                    ? null
                    : () => change(ComposerPollDraft('', ['', ''])),
                icon: const Icon(Icons.bar_chart_outlined),
                label: Text(en ? 'Add poll' : 'Thêm bình chọn'),
              ),
            );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    en ? 'Poll' : 'Bình chọn',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (!published)
                  TextButton(
                    onPressed: locked ? null : () => change(null),
                    child: Text(en ? 'Remove poll' : 'Bỏ bình chọn'),
                  ),
              ],
            ),
            ComposerTextField(
              key: const Key('composer-poll-question'),
              label: en ? 'Question' : 'Câu hỏi',
              value: input.question,
              maxLength: PollInput.questionLimit,
              utf16Limit: true,
              disabled: locked,
              onChanged: (value) =>
                  change(ComposerPollDraft(value, input.options)),
            ),
            for (var i = 0; i < input.options.length; i++)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ComposerTextField(
                        key: ValueKey('composer-poll-option-$i'),
                        label: en ? 'Choice ${i + 1}' : 'Lựa chọn ${i + 1}',
                        value: input.options[i],
                        maxLength: PollInput.optionLimit,
                        utf16Limit: true,
                        disabled: locked,
                        onChanged: (value) => change(
                          ComposerPollDraft(input.question, [
                            for (var j = 0; j < input.options.length; j++)
                              j == i ? value : input.options[j],
                          ]),
                        ),
                      ),
                    ),
                    if (!published)
                      IconButton(
                        tooltip: en ? 'Remove choice' : 'Bỏ lựa chọn',
                        onPressed:
                            locked ||
                                input.options.length <= PollInput.minOptions
                            ? null
                            : () {
                                FocusManager.instance.primaryFocus?.unfocus();
                                change(
                                  ComposerPollDraft(
                                    input.question,
                                    [...input.options]..removeAt(i),
                                  ),
                                );
                              },
                        icon: const Icon(Icons.close, size: 18),
                      ),
                  ],
                ),
              ),
            if (published)
              Text(
                en
                    ? 'This poll was published and cannot be replaced.'
                    : 'Bình chọn đã đăng, không thể thay hoặc gỡ.',
              )
            else ...[
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('composer-poll-add-choice'),
                  onPressed:
                      locked || input.options.length >= PollInput.maxOptions
                      ? null
                      : () => change(
                          ComposerPollDraft(input.question, [
                            ...input.options,
                            '',
                          ]),
                        ),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(en ? 'Add choice' : 'Thêm lựa chọn'),
                ),
              ),
              if (input.validated == null)
                Text(
                  en
                      ? 'Enter a question and 2–6 distinct choices. Unfinished input is kept on this device.'
                      : 'Nhập câu hỏi và 2–6 lựa chọn khác nhau. Nội dung chưa hoàn tất được giữ trên thiết bị.',
                ),
            ],
          ],
        ),
      ),
    );
  }
}
