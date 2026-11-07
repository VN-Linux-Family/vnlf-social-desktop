final class CommentUploadFile {
  const CommentUploadFile({
    required this.name,
    required this.mime,
    required this.length,
    required this.openRead,
  });

  final String name;
  final String mime;
  final int length;
  final Stream<List<int>> Function() openRead;
}

final class CommentUploadedAsset {
  const CommentUploadedAsset({
    required this.assetId,
    this.fileName = '',
    required this.status,
    required this.mime,
    required this.size,
  });

  final String assetId;
  final String fileName;
  final String status;
  final String mime;
  final int size;
}
