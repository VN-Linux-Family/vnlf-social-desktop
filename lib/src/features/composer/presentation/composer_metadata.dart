import 'package:flutter/material.dart';

import '../../../core/utf16_length_formatter.dart';

import '../domain/composer_draft.dart';

class ComposerMetadata extends StatelessWidget {
  const ComposerMetadata({
    super.key,
    required this.draft,
    required this.onChanged,
    required this.onCover,
    required this.onRemoveCover,
    this.disabled = false,
  });
  final ComposerDraft draft;
  final ValueChanged<ComposerDraft> onChanged;
  final VoidCallback? onCover;
  final VoidCallback? onRemoveCover;
  final bool disabled;
  @override
  Widget build(BuildContext context) {
    final en = Localizations.localeOf(context).languageCode == 'en';
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            en ? 'Cover image' : 'Ảnh bìa',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          if (draft.coverUrl != null && draft.coverUrl!.isNotEmpty) ...[
            Image.network(
              draft.coverUrl!,
              cacheWidth: 600,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.broken_image_outlined),
            ),
            TextButton(
              onPressed: onRemoveCover,
              child: Text(en ? 'Remove cover' : 'Gỡ ảnh bìa'),
            ),
          ],
          OutlinedButton.icon(
            onPressed: onCover,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(en ? 'Choose cover' : 'Chọn ảnh bìa'),
          ),
          const SizedBox(height: 16),
          ComposerTextField(
            label: en ? 'Cover alternative text' : 'Văn bản thay thế ảnh bìa',
            value: draft.coverAlt,
            maxLength: 300,
            disabled: disabled,
            onChanged: (value) => onChanged(draft.copyWith(coverAlt: value)),
          ),
          const SizedBox(height: 16),
          ComposerTextField(
            label: en ? 'Excerpt' : 'Mô tả ngắn',
            value: draft.excerpt,
            maxLength: 220,
            maxLines: 3,
            disabled: disabled,
            onChanged: (value) => onChanged(draft.copyWith(excerpt: value)),
          ),
          const SizedBox(height: 16),
          ComposerTextField(
            label: en
                ? 'Tags (up to 3, separated by commas)'
                : 'Thẻ (tối đa 3, cách nhau bằng dấu phẩy)',
            value: draft.tags.join(', '),
            disabled: disabled,
            onChanged: (value) => onChanged(
              draft.copyWith(
                tags: value
                    .split(',')
                    .map((t) => t.trim())
                    .where((t) => t.isNotEmpty)
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Server acknowledgments update values without rebuilding a field's identity.
class ComposerTextField extends StatefulWidget {
  const ComposerTextField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.maxLength,
    this.maxLines = 1,
    this.disabled = false,
    this.utf16Limit = false,
  });
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final int? maxLength;
  final int maxLines;
  final bool disabled;
  final bool utf16Limit;
  @override
  State<ComposerTextField> createState() => _ComposerTextFieldState();
}

class _ComposerTextFieldState extends State<ComposerTextField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );
  final _focus = FocusNode();
  @override
  void didUpdateWidget(covariant ComposerTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focus.hasFocus && widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    focusNode: _focus,
    readOnly: widget.disabled,
    maxLength: widget.maxLength,
    inputFormatters: widget.utf16Limit && widget.maxLength != null
        ? [Utf16LengthFormatter(widget.maxLength!)]
        : null,
    buildCounter: widget.utf16Limit
        ? (
            context, {
            required currentLength,
            required isFocused,
            required maxLength,
          }) => Text('${_controller.text.length}/${widget.maxLength}')
        : null,
    maxLines: widget.maxLines,
    onChanged: widget.onChanged,
    decoration: InputDecoration(
      labelText: widget.label,
      border: const OutlineInputBorder(),
    ),
  );
}
