import 'package:flutter/material.dart';

class ComposerPrompt extends StatelessWidget {
  const ComposerPrompt({super.key, required this.onPressed});
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(Icons.edit_note_outlined),
        title: Text(
          Localizations.localeOf(context).languageCode == 'en'
              ? 'What’s on your mind?'
              : 'Bạn đang nghĩ gì?',
        ),
        trailing: const Icon(Icons.add_photo_alternate_outlined),
        onTap: onPressed,
      ),
    ),
  );
}
