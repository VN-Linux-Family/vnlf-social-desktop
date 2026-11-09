import 'package:fleather/fleather.dart';
import 'package:flutter/material.dart';

import '../../../i18n/vi.dart';
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
            tooltip: vi.articleEditor.hoanTac,
            onPressed: !readOnly && controller.canUndo ? controller.undo : null,
            icon: const Icon(Icons.undo),
          ),
          IconButton(
            tooltip: vi.articleEditor.lamLai,
            onPressed: !readOnly && controller.canRedo ? controller.redo : null,
            icon: const Icon(Icons.redo),
          ),
          toggle(
            vi.articleEditor.dam,
            const Icon(Icons.format_bold),
            ParchmentAttribute.bold,
          ),
          toggle(
            vi.articleEditor.nghieng,
            const Icon(Icons.format_italic),
            ParchmentAttribute.italic,
          ),
          toggle(
            vi.app.composer.gachNgang,
            const Icon(Icons.strikethrough_s),
            ParchmentAttribute.strikethrough,
          ),
          toggle(
            vi.app.composer.maTrongDong,
            const Icon(Icons.code),
            ParchmentAttribute.inlineCode,
          ),
          toggle(
            vi.articleEditor.headingLon,
            const Text('H2'),
            ParchmentAttribute.h2,
          ),
          toggle(
            vi.articleEditor.headingNho,
            const Text('H3'),
            ParchmentAttribute.h3,
          ),
          toggle(
            vi.articleEditor.danhSach,
            const Icon(Icons.format_list_bulleted),
            ParchmentAttribute.ul,
          ),
          toggle(
            vi.app.composer.danhSachDanhSo,
            const Icon(Icons.format_list_numbered),
            ParchmentAttribute.ol,
          ),
          toggle(
            vi.articleEditor.trichDan,
            const Icon(Icons.format_quote),
            ParchmentAttribute.bq,
          ),
          toggle(
            vi.app.composer.khoiMa,
            const Icon(Icons.terminal),
            ParchmentAttribute.code,
          ),
          IconButton(
            tooltip: vi.articleEditor.lienKet,
            icon: const Icon(Icons.link),
            onPressed: readOnly ? null : () => _link(context),
          ),
          IconButton(
            tooltip: vi.articleEditor.duongPhanCach,
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
