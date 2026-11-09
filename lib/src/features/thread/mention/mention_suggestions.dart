import 'package:flutter/material.dart';

import '../../../i18n/vi.dart';
import 'mention_controller.dart';

/// Place above the comment input and route its focus key events to handleKey.
final class MentionSuggestions extends StatelessWidget {
  const MentionSuggestions({super.key, required this.controller});
  final MentionController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      if (controller.error != null) {
        return Semantics(
          liveRegion: true,
          child: Text(vi.app.thread.khongTaiDuocGoi),
        );
      }
      if (controller.items.isEmpty) return const SizedBox.shrink();
      final colors = Theme.of(context).colorScheme;
      return Semantics(
        label: vi.app.thread.nhacDenThanhVien,
        child: Material(
          color: colors.surface,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: colors.outlineVariant),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < controller.items.length; i++)
                Builder(
                  builder: (context) {
                    final person = controller.items[i];
                    return Semantics(
                      selected: i == controller.active,
                      button: true,
                      child: InkWell(
                        onTap: () => controller.pick(person),
                        child: Container(
                          color: i == controller.active
                              ? colors.secondaryContainer
                              : null,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundImage:
                                    person.avatarUrl == null ||
                                        person.avatarUrl!.isEmpty
                                    ? null
                                    : NetworkImage(person.avatarUrl!),
                                child:
                                    person.avatarUrl == null ||
                                        person.avatarUrl!.isEmpty
                                    ? Text(
                                        person.displayName.isEmpty
                                            ? '?'
                                            : person
                                                  .displayName
                                                  .characters
                                                  .first,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      person.displayName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '@${person.username}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}
