import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../design_system/design_system.dart';
import '../domain/poll_models.dart';
import 'poll_edit_dialog.dart';
import 'poll_feedback.dart';
import 'poll_state.dart';

class PollCard extends ConsumerWidget {
  const PollCard({
    super.key,
    required this.poll,
    required this.authorId,
    this.disabled = false,
    this.maxWidth = 420,
  });
  final Poll poll;
  final String authorId;
  final bool disabled;
  final double maxWidth;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = VnlfColors.of(context);
    final en = Localizations.localeOf(context).languageCode == 'en';
    final owner = ref.watch(
      sessionStateProvider.select((session) => session?.userId),
    );
    final current = ref.watch(
      pollStoreProvider.select((state) => state[poll.id]),
    );
    final value = current?.poll ?? poll;
    final voted = value.viewerOptionId != null;
    final pending = current?.pending ?? false;
    final canEdit = owner != null && owner == authorId && value.totalVotes == 0;
    // Interactions within the poll must not open the parent feed card.
    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: GestureDetector(
          excludeFromSemantics: true,
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border.all(color: colors.line),
              borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.bar_chart, size: 15, color: colors.brand),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        value.question,
                        style: VnlfTypography.body(colors.ink)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (final option in value.options)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        VnlfDimensions.radiusMd,
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.surfaceSoft,
                          border: Border.all(
                            color: value.viewerOptionId == option.id
                                ? colors.brand
                                : colors.line,
                          ),
                          borderRadius: BorderRadius.circular(
                            VnlfDimensions.radiusMd,
                          ),
                        ),
                        child: Stack(
                          children: [
                            if (voted)
                              Positioned.fill(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: FractionallySizedBox(
                                    heightFactor: 1,
                                    widthFactor: value.totalVotes == 0
                                        ? 0
                                        : (option.votes / value.totalVotes)
                                              .clamp(0.0, 1.0),
                                    child: ColoredBox(color: colors.brandSoft),
                                  ),
                                ),
                              ),
                            Semantics(
                              selected: value.viewerOptionId == option.id,
                              child: TextButton(
                                key: ValueKey(
                                  'poll-choice-${value.id}-${option.id}',
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: colors.ink,
                                  disabledForegroundColor: colors.muted,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  minimumSize: Size(
                                    double.infinity,
                                    VnlfViewportSize.fromWidth(
                                              MediaQuery.sizeOf(context).width,
                                            ) ==
                                            VnlfViewportSize.mobile
                                        ? 44
                                        : 40,
                                  ),
                                  alignment: Alignment.centerLeft,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      VnlfDimensions.radiusMd,
                                    ),
                                  ),
                                ),
                                onPressed: disabled || pending
                                    ? null
                                    : () {
                                        if (owner == null) {
                                          GoRouter.maybeOf(context)
                                              ?.push('/login');
                                          return;
                                        }
                                        ref
                                            .read(pollStoreProvider.notifier)
                                            .vote(
                                              value,
                                              value.viewerOptionId == option.id
                                                  ? null
                                                  : option.id,
                                            );
                                      },
                                child: Row(
                                  children: [
                                    if (value.viewerOptionId == option.id) ...[
                                      Icon(
                                        Icons.check,
                                        size: 14,
                                        color: colors.brand,
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    Expanded(
                                      child: Text(
                                        option.label,
                                        style: VnlfTypography.body(colors.ink),
                                      ),
                                    ),
                                    if (voted) ...[
                                      const SizedBox(width: 10),
                                      Text(
                                        '${value.totalVotes == 0 ? 0 : (option.votes / value.totalVotes * 100).round()}%',
                                        style: VnlfTypography.meta(
                                          colors.muted,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (pending) const LinearProgressIndicator(minHeight: 2),
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${value.totalVotes} ${en ? 'votes' : 'lượt bình chọn'}${voted ? (en ? ' · Select again to remove' : ' · Bấm lại để bỏ') : ''}',
                      style: VnlfTypography.meta(colors.muted),
                    ),
                    if (canEdit)
                      TextButton.icon(
                        key: ValueKey('poll-edit-${value.id}'),
                        onPressed: disabled || pending
                            ? null
                            : () => showDialog<void>(
                                context: context,
                                builder: (_) => PollEditDialog(
                                  poll: value,
                                  authorId: authorId,
                                ),
                              ),
                        icon: const Icon(Icons.edit_outlined, size: 13),
                        label: Text(en ? 'Edit poll' : 'Sửa bình chọn'),
                      ),
                  ],
                ),
                if (current?.failure case final failure?)
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      pollFailureText(context, failure),
                      key: ValueKey('poll-error-${value.id}'),
                      style: VnlfTypography.meta(colors.red),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
