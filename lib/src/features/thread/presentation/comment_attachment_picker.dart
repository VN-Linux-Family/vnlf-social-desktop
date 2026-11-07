import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../direct_messages/presentation/dm_attachment_picker.dart';
import '../domain/comment_upload.dart';

final commentAttachmentPickerProvider =
    Provider<Future<List<CommentUploadFile>> Function()>((ref) {
      final pick = ref.watch(dmAttachmentPickerProvider);
      return () async => [
        for (final file in await pick())
          CommentUploadFile(
            name: file.name,
            mime: file.mime,
            length: file.length,
            openRead: file.openRead,
          ),
      ];
    });
