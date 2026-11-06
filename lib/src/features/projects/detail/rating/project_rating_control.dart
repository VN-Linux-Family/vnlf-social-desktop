import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/api_client.dart';

/// A server-confirmed rating summary. Distribution is ordered from 1 to 5.
class ProjectRatingSnapshot {
  const ProjectRatingSnapshot({
    required this.average,
    required this.count,
    required this.myRating,
    required this.distribution,
  });
  final double? average;
  final int count;
  final int? myRating;
  final List<int> distribution;
}

abstract interface class ProjectRatingRepository {
  Future<ProjectRatingSnapshot> setRating(String projectId, int? score);
}

final projectRatingRepositoryProvider = Provider<ProjectRatingRepository>(
  (ref) => ApiProjectRatingRepository(ref.watch(apiClientProvider)),
);

class ApiProjectRatingRepository implements ProjectRatingRepository {
  const ApiProjectRatingRepository(this.client);
  final ApiClient client;

  @override
  Future<ProjectRatingSnapshot> setRating(String projectId, int? score) {
    if (projectId.isEmpty || (score != null && (score < 1 || score > 5))) {
      throw const ParseFailure('rating');
    }
    return client.request<ProjectRatingSnapshot>(
      score == null ? 'DELETE' : 'PUT',
      '/api/v1/projects/${Uri.encodeComponent(projectId)}/rating',
      body: score == null ? null : jsonEncode({'score': score}),
      decode: (json) => _decodeAcknowledgement(json, score),
    );
  }
}

ProjectRatingSnapshot _decodeAcknowledgement(
  Map<String, dynamic> json,
  int? expected,
) {
  final rating = json['rating'];
  final distribution = json['ratingDistribution'];
  final mine = json['myRating'];
  if (rating is! Map ||
      !rating.containsKey('average') ||
      !json.containsKey('myRating') ||
      mine != expected ||
      distribution is! List ||
      distribution.length != 5 ||
      distribution.any((v) => v is! int || v < 0)) {
    throw const ParseFailure('rating acknowledgement');
  }
  final average = rating['average'];
  final count = rating['count'];
  if (count is! int ||
      count < 0 ||
      (average != null &&
          (average is! num ||
              !average.isFinite ||
              average < 1 ||
              average > 5)) ||
      (count == 0) != (average == null)) {
    throw const ParseFailure('rating acknowledgement');
  }
  final values = distribution.cast<int>();
  // The server reads the aggregate, distribution and viewer rating in separate
  // queries after the write, so concurrent votes can make their counts differ.
  return ProjectRatingSnapshot(
    average: (average as num?)?.toDouble(),
    count: count,
    myRating: expected,
    distribution: List.unmodifiable(values),
  );
}

class ProjectRatingState {
  const ProjectRatingState({
    required this.data,
    required this.canRate,
    this.pending = false,
    this.error = false,
  });
  final ProjectRatingSnapshot data;
  final bool canRate;
  final bool pending;
  final bool error;
}

class ProjectRatingController extends StateNotifier<ProjectRatingState> {
  ProjectRatingController(
    this.repository,
    this.projectId,
    ProjectRatingSnapshot initial,
    bool canRate,
  ) : super(ProjectRatingState(data: initial, canRate: canRate));
  final ProjectRatingRepository repository;
  final String projectId;
  int _generation = 0;
  bool _invalidated = false;
  ProjectRatingState get currentState => state;
  bool _changed = false;

  /// Initial detail is only accepted before any local operation or session change.
  void replaceInitial(ProjectRatingSnapshot initial, bool canRate) {
    if (_invalidated || _changed || state.pending) {
      if (!canRate && state.canRate) {
        _generation++;
        state = ProjectRatingState(
          data: state.data,
          canRate: false,
          error: state.error,
        );
      }
      return;
    }
    state = ProjectRatingState(data: initial, canRate: canRate);
  }

  void invalidateSession() {
    _generation++;
    _invalidated = true;
    final old = state.data;
    state = ProjectRatingState(
      data: ProjectRatingSnapshot(
        average: old.average,
        count: old.count,
        myRating: null,
        distribution: old.distribution,
      ),
      canRate: false,
    );
  }

  Future<void> save(int? score) async {
    if (!state.canRate ||
        state.pending ||
        (score != null && (score < 1 || score > 5))) {
      return;
    }
    _changed = true;
    final generation = ++_generation;
    final previous = state.data;
    state = ProjectRatingState(data: previous, canRate: true, pending: true);
    try {
      final result = await repository.setRating(projectId, score);
      if (!mounted || generation != _generation) return;
      state = ProjectRatingState(data: result, canRate: true);
    } catch (_) {
      if (!mounted || generation != _generation) return;
      state = ProjectRatingState(data: previous, canRate: true, error: true);
    }
  }

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }
}

/// Remount with a new key after a fresh, session-guarded detail load.
class ProjectRatingControl extends ConsumerStatefulWidget {
  const ProjectRatingControl({
    super.key,
    required this.projectId,
    required this.initialAverage,
    required this.initialCount,
    required this.initialMyRating,
    required this.initialDistribution,
    required this.canRate,
    this.onRefresh,
  });
  final String projectId;
  final double? initialAverage;
  final int initialCount;
  final int? initialMyRating;
  final List<int> initialDistribution;
  final bool canRate;
  final VoidCallback? onRefresh;

  @override
  ConsumerState<ProjectRatingControl> createState() =>
      _ProjectRatingControlState();
}

class _ProjectRatingControlState extends ConsumerState<ProjectRatingControl> {
  late ProjectRatingController controller;
  late void Function() stopObserving;
  late void Function() stopListening;
  ProjectRatingSnapshot get initial => ProjectRatingSnapshot(
    average: widget.initialAverage,
    count: widget.initialCount,
    myRating: widget.initialMyRating,
    distribution: List.unmodifiable(widget.initialDistribution),
  );

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    controller = ProjectRatingController(
      ref.read(projectRatingRepositoryProvider),
      widget.projectId,
      initial,
      widget.canRate,
    );
    stopObserving = ref
        .read(apiClientProvider)
        .observeSessionInvalidation(controller.invalidateSession);
    stopListening = controller.addListener((_) {
      if (mounted) setState(() {});
    }, fireImmediately: false);
  }

  @override
  void didUpdateWidget(covariant ProjectRatingControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectId != widget.projectId) {
      stopObserving();
      stopListening();
      controller.dispose();
      _start();
    } else {
      controller.replaceInitial(initial, widget.canRate);
    }
  }

  @override
  void dispose() {
    stopObserving();
    stopListening();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final en = Localizations.localeOf(context).languageCode == 'en';
    final state = controller.currentState;
    final data = state.data;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data.average == null
              ? (en ? 'No ratings yet' : 'Chưa có đánh giá')
              : '${data.average!.toStringAsFixed(1)} / 5 · ${data.count} ${en ? 'ratings' : 'đánh giá'}',
        ),
        if (data.count > 0)
          for (var score = 5; score >= 1; score--)
            Text(
              '$score ★  ${data.distribution.length >= score ? data.distribution[score - 1] : 0}',
            ),
        if (data.myRating != null)
          Text(
            '${en ? 'Your rating' : 'Đánh giá của bạn'}: ${data.myRating} / 5',
          ),
        if (state.canRate) ...[
          Wrap(
            children: [
              for (var score = 1; score <= 5; score++)
                Semantics(
                  selected: data.myRating == score,
                  button: true,
                  child: IconButton(
                    tooltip: en ? '$score stars' : '$score sao',
                    onPressed: state.pending || state.error
                        ? null
                        : () => controller.save(score),
                    icon: Icon(
                      data.myRating != null && score <= data.myRating!
                          ? Icons.star
                          : Icons.star_border,
                    ),
                  ),
                ),
            ],
          ),
          if (data.myRating != null)
            TextButton(
              onPressed: state.pending || state.error
                  ? null
                  : () => controller.save(null),
              child: Text(en ? 'Remove rating' : 'Bỏ đánh giá'),
            ),
        ],
        if (state.pending) Text(en ? 'Saving…' : 'Đang lưu…'),
        if (state.error)
          Text(
            en
                ? 'Could not confirm the rating. Refresh before trying again.'
                : 'Chưa xác nhận được đánh giá. Hãy làm mới trước khi thử lại.',
          ),
        if (state.error && widget.onRefresh != null)
          TextButton(
            onPressed: widget.onRefresh,
            child: Text(en ? 'Refresh' : 'Làm mới'),
          ),
      ],
    );
  }
}
