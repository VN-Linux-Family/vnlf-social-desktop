import 'package:fleather/fleather.dart';
import 'package:flutter/material.dart';

import 'composer_link_dialog.dart';

class ComposerToolbar extends StatelessWidget {
  const ComposerToolbar({
    super.key,
    required this.controller,
    this.readOnly = false,
  });
  final FleatherController controller;
  final bool readOnly;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final en = Localizations.localeOf(context).languageCode == 'en';
      final style = controller.getSelectionStyle();
      Widget toggle(
        String label,
        Widget icon,
        ParchmentAttribute<dynamic> attribute,
      ) => IconButton(
        tooltip: label,
        icon: icon,
        isSelected: style.containsSame(attribute),
        onPressed: readOnly
            ? null
            : () => controller.formatSelection(
                style.containsSame(attribute) ? attribute.unset : attribute,
              ),
      );
      return Wrap(
        children: [
          IconButton(
            tooltip: en ? 'Undo' : 'Hoàn tác',
            onPressed: !readOnly && controller.canUndo ? controller.undo : null,
            icon: const Icon(Icons.undo),
          ),
          IconButton(
            tooltip: en ? 'Redo' : 'Làm lại',
            onPressed: !readOnly && controller.canRedo ? controller.redo : null,
            icon: const Icon(Icons.redo),
          ),
          toggle(
            en ? 'Bold' : 'Đậm',
            const Icon(Icons.format_bold),
            ParchmentAttribute.bold,
          ),
          toggle(
            en ? 'Italic' : 'Nghiêng',
            const Icon(Icons.format_italic),
            ParchmentAttribute.italic,
          ),
          toggle(
            en ? 'Strikethrough' : 'Gạch ngang',
            const Icon(Icons.strikethrough_s),
            ParchmentAttribute.strikethrough,
          ),
          toggle(
            en ? 'Inline code' : 'Mã trong dòng',
            const Icon(Icons.code),
            ParchmentAttribute.inlineCode,
          ),
          toggle(
            en ? 'Large heading' : 'Tiêu đề lớn',
            const Text('H2'),
            ParchmentAttribute.h2,
          ),
          toggle(
            en ? 'Small heading' : 'Tiêu đề nhỏ',
            const Text('H3'),
            ParchmentAttribute.h3,
          ),
          toggle(
            en ? 'Bullet list' : 'Danh sách',
            const Icon(Icons.format_list_bulleted),
            ParchmentAttribute.ul,
          ),
          toggle(
            en ? 'Numbered list' : 'Danh sách đánh số',
            const Icon(Icons.format_list_numbered),
            ParchmentAttribute.ol,
          ),
          toggle(
            en ? 'Quote' : 'Trích dẫn',
            const Icon(Icons.format_quote),
            ParchmentAttribute.bq,
          ),
          toggle(
            en ? 'Code block' : 'Khối mã',
            const Icon(Icons.terminal),
            ParchmentAttribute.code,
          ),
          IconButton(
            tooltip: en ? 'Link' : 'Liên kết',
            icon: const Icon(Icons.link),
            onPressed: readOnly ? null : () => _link(context),
          ),
          IconButton(
            tooltip: en ? 'Horizontal rule' : 'Đường phân cách',
            icon: const Icon(Icons.horizontal_rule),
            onPressed: readOnly
                ? null
                : () {
                    final offset = controller.selection.start.clamp(
                      0,
                      controller.document.length - 1,
                    );
                    controller.replaceText(
                      offset,
                      0,
                      BlockEmbed(
                        'hr',
                        data: const {
                          'node': {'type': 'horizontalRule'},
                        },
                      ),
                    );
                  },
          ),
        ],
      );
    },
  );
  Future<void> _link(BuildContext context) async {
    final link = await showDialog<String>(
      context: context,
      builder: (_) => ComposerLinkDialog(
        initialValue:
            controller.getSelectionStyle().value(ParchmentAttribute.link) ?? '',
      ),
    );
    if (link != null && context.mounted) {
      controller.formatSelection(
        link.isEmpty
            ? ParchmentAttribute.link.unset
            : ParchmentAttribute.link.fromString(link),
      );
    }
  }
}
