import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../shared/presentation/feature_samples.dart';
import '../data/klipy_repository.dart';
import '../data/stickers_repository.dart';
import '../domain/stickers.dart';

final klipyRepositoryProvider = Provider<KlipyRepository>(
  (ref) => offlineFeatures
      ? const FixtureKlipyRepository()
      : LiveKlipyRepository(ref.watch(apiClientProvider)),
);

final stickersRepositoryProvider = Provider<StickersRepository>(
  (ref) => offlineFeatures
      ? const FixtureStickersRepository()
      : LiveStickersRepository(ref.watch(apiClientProvider)),
);

final recentStickersStoreProvider = Provider<RecentStickersStore>(
  (ref) => RecentStickersStore(ref.watch(preferencesStorageProvider)),
);

String _owner(Ref ref) =>
    ref.watch(sessionStateProvider.select((session) => session?.userId)) ?? '';

/// The KLIPY config is per account, like everything signed in.
final klipyConfigProvider = FutureProvider.autoDispose<KlipyConfig>((ref) {
  _owner(ref);
  return ref.watch(klipyRepositoryProvider).config();
});

final stickerTrayProvider = FutureProvider.autoDispose<List<StickerPack>>((
  ref,
) {
  _owner(ref);
  return ref.watch(stickersRepositoryProvider).tray();
});

final savedStickersProvider = FutureProvider.autoDispose<List<SavedSticker>>((
  ref,
) {
  _owner(ref);
  return ref.watch(stickersRepositoryProvider).saved();
});

final recentStickersProvider = FutureProvider.autoDispose<List<GifChoice>>((
  ref,
) {
  return ref.watch(recentStickersStoreProvider).read(_owner(ref));
});
