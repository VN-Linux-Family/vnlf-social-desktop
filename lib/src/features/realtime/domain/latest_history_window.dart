/// Replaces the covered range of a latest-page read while retaining older pages.
/// Mutations arriving during the read must subsequently pass through a read ticket.
List<T> latestHistoryWindow<T>({
  required Iterable<T> current,
  required List<T> incoming,
  required bool hasOlder,
  required String Function(T) idOf,
  required DateTime? Function(T) createdAt,
}) {
  if (!hasOlder) return List.unmodifiable(incoming);
  if (incoming.isEmpty || incoming.any((m) => createdAt(m) == null)) {
    return [...current, ...incoming];
  }
  int compare(T a, T b) {
    final time = createdAt(a)!.compareTo(createdAt(b)!);
    return time == 0 ? idOf(a).compareTo(idOf(b)) : time;
  }

  final oldest = incoming.reduce((a, b) => compare(a, b) <= 0 ? a : b);
  return [
    ...current.where((m) => createdAt(m) == null || compare(m, oldest) < 0),
    ...incoming,
  ];
}
