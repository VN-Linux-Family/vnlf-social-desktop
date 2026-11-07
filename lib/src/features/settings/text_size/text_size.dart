import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/preferences_storage.dart';

const textSizeMinimum = 12;
const textSizeMaximum = 18;
const textSizeDefault = 13;
const _storageKey = 'vnlf_text_size';

@immutable
class TextSizeState {
  const TextSizeState({this.size = textSizeDefault, this.storageFailure = false});

  final int size;
  final bool storageFailure;
}

final textSizeProvider = StateNotifierProvider<TextSizeController, TextSizeState>(
  (ref) => TextSizeController(ref.watch(preferencesStorageProvider)),
);

class TextSizeController extends StateNotifier<TextSizeState> {
  TextSizeController(this._storage) : super(const TextSizeState()) {
    restored = _restore();
  }

  final PreferencesStorage _storage;
  late final Future<void> restored;
  Future<void> _writes = Future<void>.value();
  int _revision = 0;

  Future<void> _restore() async {
    final revision = _revision;
    try {
      final stored = int.tryParse(await _storage.read(_storageKey) ?? '');
      if (!mounted || revision != _revision) return;
      state = TextSizeState(
        size: stored != null && stored >= textSizeMinimum && stored <= textSizeMaximum
            ? stored
            : textSizeDefault,
      );
    } catch (_) {
      if (mounted && revision == _revision) {
        state = TextSizeState(size: state.size, storageFailure: true);
      }
    }
  }

  /// Updates the display immediately; call [commit] when interaction ends.
  void preview(int size) {
    ++_revision;
    state = TextSizeState(
      size: size.clamp(textSizeMinimum, textSizeMaximum),
      storageFailure: state.storageFailure,
    );
  }

  Future<void> commit() {
    final revision = ++_revision;
    final size = state.size;
    return _writes = _writes.then((_) async {
      try {
        await _storage.write(_storageKey, '$size');
        if (mounted && revision == _revision) {
          state = TextSizeState(size: state.size);
        }
      } catch (_) {
        if (mounted && revision == _revision) {
          state = TextSizeState(size: state.size, storageFailure: true);
        }
      }
    });
  }

  Future<void> reset() {
    preview(textSizeDefault);
    return commit();
  }
}

/// Applies the preference before the platform scaler, retaining nonlinear scaling.
class PreferenceTextScaler extends TextScaler {
  const PreferenceTextScaler(this.device, this.size);

  final TextScaler device;
  final int size;

  @override
  double scale(double fontSize) => device.scale(fontSize * size / textSizeDefault);

  @override
  double get textScaleFactor => scale(14) / 14;

  @override
  bool operator ==(Object other) =>
      other is PreferenceTextScaler && other.device == device && other.size == size;

  @override
  int get hashCode => Object.hash(device, size);
}

/// Place inside a MaterialApp builder, using its incoming device MediaQuery.
class TextSizeScope extends ConsumerWidget {
  const TextSizeScope({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = MediaQuery.of(context);
    final size = ref.watch(textSizeProvider.select((value) => value.size));
    return MediaQuery(
      data: media.copyWith(textScaler: PreferenceTextScaler(media.textScaler, size)),
      child: child,
    );
  }
}

/// Self-contained settings control; persistence errors remain visible until saved.
class TextSizeSettings extends ConsumerWidget {
  const TextSizeSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(textSizeProvider);
    final controller = ref.read(textSizeProvider.notifier);
    final english = Localizations.maybeLocaleOf(context)?.languageCode == 'en';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(english ? 'Text size' : 'Cỡ chữ'),
        Slider(
          value: value.size.toDouble(),
          min: textSizeMinimum.toDouble(),
          max: textSizeMaximum.toDouble(),
          divisions: textSizeMaximum - textSizeMinimum,
          label: '${value.size}',
          semanticFormatterCallback: (size) => '${size.round()} px',
          onChanged: (size) => controller.preview(size.round()),
          onChangeEnd: (_) => unawaited(controller.commit()),
        ),
        TextButton(
          onPressed: () => unawaited(controller.reset()),
          child: Text(english ? 'Reset' : 'Đặt lại'),
        ),
        if (value.storageFailure)
          Text(
            english ? 'Could not save or load text size.' : 'Không thể lưu hoặc tải cỡ chữ.',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    );
  }
}
