import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'composer_providers.dart';

Future<String?> chooseServerDraft(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (_) => Consumer(
      builder: (context, ref, _) {
        final drafts = ref.watch(composerDraftsProvider);
        return SafeArea(
          child: SizedBox(
            height: 450,
            child: drafts.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: TextButton(
                  onPressed: () => ref.invalidate(composerDraftsProvider),
                  child: Text(
                    Localizations.localeOf(context).languageCode == 'en'
                        ? 'Retry loading drafts'
                        : 'Tải lại bản nháp',
                  ),
                ),
              ),
              data: (items) => items.isEmpty
                  ? Center(
                      child: Text(
                        Localizations.localeOf(context).languageCode == 'en'
                            ? 'No server drafts yet'
                            : 'Chưa có bản nháp trên máy chủ',
                      ),
                    )
                  : ListView(
                      children: [
                        for (final draft in items)
                          ListTile(
                            title: Text(
                              draft.title.isEmpty
                                  ? draft.excerpt.isEmpty
                                        ? (Localizations.localeOf(context)
                                                      .languageCode ==
                                                  'en'
                                              ? 'Untitled draft'
                                              : 'Bản nháp chưa có tiêu đề')
                                        : draft.excerpt
                                  : draft.title,
                            ),
                            subtitle: Text(draft.format),
                            onTap: () => Navigator.pop(context, draft.id),
                          ),
                      ],
                    ),
            ),
          ),
        );
      },
    ),
  );
}
