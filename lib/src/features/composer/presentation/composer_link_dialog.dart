import 'package:flutter/material.dart';

import '../../../core/external_uri.dart';
import '../../../i18n/vi.dart';

class ComposerLinkDialog extends StatefulWidget {
  const ComposerLinkDialog({super.key, required this.initialValue});
  final String initialValue;

  @override
  State<ComposerLinkDialog> createState() => _ComposerLinkDialogState();
}

class _ComposerLinkDialogState extends State<ComposerLinkDialog> {
  final _form = GlobalKey<FormState>();
  late final _input = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _apply() {
    if (_form.currentState!.validate()) {
      Navigator.pop(context, _input.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(vi.articleEditor.lienKet),
      content: Form(
        key: _form,
        child: TextFormField(
          controller: _input,
          autofocus: true,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _apply(),
          decoration: const InputDecoration(
            labelText: 'URL',
            hintText: 'https://…',
          ),
          validator: (input) {
            final value = input?.trim() ?? '';
            final uri = Uri.tryParse(value);
            final emailLink = uri?.scheme == 'mailto' && uri!.path.isNotEmpty;
            return externalWebUri(value) != null || emailLink
                ? null
                : vi.app.composer.nhapLienKetWeb;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(vi.common.huy),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, ''),
          child: Text(vi.app.composer.goLienKet),
        ),
        FilledButton(onPressed: _apply, child: Text(vi.articleEditor.apDung)),
      ],
    );
  }
}
