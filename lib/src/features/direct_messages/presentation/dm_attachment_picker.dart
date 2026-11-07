import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/direct_message_models.dart';

typedef DmAttachmentPicker = Future<List<DmUploadFile>> Function();
final dmAttachmentPickerProvider = Provider<DmAttachmentPicker>((ref) => _pick);

Future<List<DmUploadFile>> _pick() async {
  final files = await openFiles(
    acceptedTypeGroups: const [
      XTypeGroup(
        label: 'Images',
        extensions: ['jpg', 'jpeg', 'png', 'webp', 'gif'],
        mimeTypes: ['image/jpeg', 'image/png', 'image/webp', 'image/gif'],
      ),
    ],
  );
  const mimes = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'gif': 'image/gif',
  };
  return [
    for (final file in files)
      DmUploadFile(
        name: file.name,
        mime:
            file.mimeType ??
            mimes[file.name.split('.').last.toLowerCase()] ??
            '',
        length: await file.length(),
        openRead: file.openRead,
      ),
  ];
}
