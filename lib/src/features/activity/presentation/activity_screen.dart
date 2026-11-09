import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../../i18n/vi.dart';
import '../domain/activity_models.dart';
import '../domain/activity_service.dart';

/// Native personal activity view. The parent supplies the session-bound
/// service so route and account lifecycle wiring remain app-owned.
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key, required this.service, this.clock});

  final ActivityService service;
  final DateTime Function()? clock;

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

/// Celebration surface for the app lifecycle coordinator to show when a
/// check-in acknowledgment has `showCelebration == true`.
class ActivityCheckInCelebration extends StatelessWidget {
  const ActivityCheckInCelebration({
    super.key,
    required this.acknowledgment,
    this.onViewActivity,
    this.onContinue,
  });

  final CheckInAcknowledgment acknowledgment;
  final VoidCallback? onViewActivity;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final year = int.parse(acknowledgment.date.substring(0, 4));
    final month = int.parse(acknowledgment.date.substring(5, 7));
    final checkins = {
      for (final day in acknowledgment.checkins) day.date: day.streakDay,
    };
    final range = activityMonthRange(year, month);
    final days = <ActivityDay>[];
    for (
      var date = range.from;
      date.compareTo(range.to) <= 0;
      date = shiftActivityDay(date, 1)
    ) {
      days.add(
        ActivityDay(
          date: date,
          points: 0,
          checkedIn: checkins.containsKey(date),
          streakDay: checkins[date] ?? 0,
        ),
      );
    }

    return AlertDialog(
      title: Text(vi.app.activity.diemDanhHangNgay),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                format(vi.app.activity.banDaDiemDanh, {
                  'currentStreak': acknowledgment.currentStreak,
                }),
                style: VnlfTypography.body(colors.ink),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 420,
                height: 400,
                child: _CalendarGrid(
                  days: days,
                  today: acknowledgment.date,
                  selectedDate: null,
                  colors: colors,
                  selectable: false,
                  onSelect: (_) {},
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (onViewActivity != null)
          TextButton(
            onPressed: onViewActivity,
            child: Text(vi.dailyCheckin.xemLichHoatDong),
          ),
        FilledButton(
          onPressed: onContinue ?? () => Navigator.of(context).pop(),
          child: Text(vi.dailyCheckin.tiepTuc),
        ),
      ],
    );
  }
}

class _ActivityScreenState extends State<ActivityScreen>
    with WidgetsBindingObserver {
  late DateTime _today;
  Timer? _dayTimer;
  late int _year;
  late int _month;
  String? _selectedDate;
  late Future<ActivityCalendarData> _calendar;
  int _loadRevision = 0;
  bool _checkingIn = false;
  bool _loadingUncertainty = true;
  bool _storageError = false;
  bool _unconfirmed = false;
  bool _refreshingCheckIn = false;
  String? _checkInMessage;

  Future<void> _checkIn() async {
    if (_checkingIn || _unconfirmed || _refreshingCheckIn) return;
    final service = widget.service;
    final uncertainty = service.uncertainty;
    if (uncertainty == null) {
      setState(() => _storageError = true);
      return;
    }
    if (!uncertainty.tryAcquire()) {
      setState(() => _unconfirmed = true);
      return;
    }
    var leaseOwned = true;
    setState(() {
      _checkingIn = true;
      _checkInMessage = null;
    });
    try {
      try {
        if (await uncertainty.read()) {
          if (mounted && service == widget.service) {
            setState(() => _unconfirmed = true);
          }
          return;
        }
        await uncertainty.mark();
      } catch (_) {
        if (mounted && service == widget.service) {
          setState(() => _storageError = true);
        }
        return;
      }
      if (!mounted || service != widget.service) return;
      setState(() => _unconfirmed = true);
      final acknowledgment = await service.checkIn(claimCelebration: true);
      if (!mounted || service != widget.service) return;
      setState(() {
        _checkInMessage = 'confirmed';
      });
      await _refreshCheckIn(afterAcknowledgment: true, leaseHeld: true);
      if (!mounted || service != widget.service) return;
      if (acknowledgment.showCelebration) {
        uncertainty.release();
        leaseOwned = false;
        await showDialog<void>(
          context: context,
          builder: (_) =>
              ActivityCheckInCelebration(acknowledgment: acknowledgment),
        );
      }
    } catch (_) {
      if (!mounted || service != widget.service) return;
      setState(() {
        _unconfirmed = true;
        if (_checkInMessage != 'confirmed') {
          _checkInMessage = 'unconfirmed';
        }
      });
    } finally {
      if (leaseOwned) uncertainty.release();
      if (mounted && service == widget.service) {
        setState(() => _checkingIn = false);
      }
    }
  }

  Future<void> _refreshCheckIn({
    bool afterAcknowledgment = false,
    bool leaseHeld = false,
  }) async {
    if (_refreshingCheckIn || (_checkingIn && !afterAcknowledgment)) return;
    final service = widget.service;
    final year = _today.year;
    final month = _today.month;
    final day = activityDayString(widget.clock?.call() ?? DateTime.now());
    final revision = _loadRevision;
    final uncertainty = service.uncertainty;
    if (uncertainty == null) {
      setState(() => _storageError = true);
      return;
    }
    if (!leaseHeld && !uncertainty.tryAcquire()) return;
    bool isCurrent() =>
        mounted &&
        service == widget.service &&
        revision == _loadRevision &&
        day == activityDayString(widget.clock?.call() ?? DateTime.now());
    setState(() => _refreshingCheckIn = true);
    try {
      final data = await service.loadMonth(year, month);
      if (!isCurrent()) return;
      if (data.today != day || !data.days.any((item) => item.date == day)) {
        throw StateError('Calendar does not include today');
      }
      await uncertainty.clear();
      if (!isCurrent()) {
        await uncertainty.mark();
        return;
      }
      setState(() {
        _year = year;
        _month = month;
        _selectedDate = null;
        _loadRevision++;
        _calendar = Future.value(data);
        _unconfirmed = false;
        _checkInMessage = afterAcknowledgment ? 'confirmed' : 'refreshed';
        _storageError = false;
      });
    } catch (_) {
      // Keep the unconfirmed state until a fresh owner-bound read succeeds.
    } finally {
      if (!leaseHeld) uncertainty.release();
      if (mounted && service == widget.service) {
        setState(() => _refreshingCheckIn = false);
      }
    }
  }

  @override
  void didUpdateWidget(covariant ActivityScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.service != widget.service) {
      _loadRevision++;
      _checkingIn = false;
      _unconfirmed = false;
      _refreshingCheckIn = false;
      _checkInMessage = null;
      _loadingUncertainty = true;
      _storageError = false;
      _loadUncertainty();
      _calendar = widget.service.loadMonth(_year, _month);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final now = _vietnamNow();
    _today = DateTime.utc(now.year, now.month, now.day);
    _year = now.year;
    _month = now.month;
    _calendar = widget.service.loadMonth(_year, _month);
    _scheduleDayChange();
    _loadUncertainty();
  }

  Future<void> _loadUncertainty() async {
    final service = widget.service;
    try {
      final uncertainty = service.uncertainty;
      if (uncertainty == null) throw StateError('Storage unavailable');
      final pending = await uncertainty.read();
      if (!mounted || service != widget.service) return;
      setState(() {
        _unconfirmed = pending;
        _loadingUncertainty = false;
        _storageError = false;
      });
    } catch (_) {
      if (!mounted || service != widget.service) return;
      setState(() {
        _loadingUncertainty = false;
        _storageError = true;
      });
    }
  }

  DateTime _vietnamNow() => (widget.clock?.call() ?? DateTime.now())
      .toUtc()
      .add(const Duration(hours: 7));

  void _scheduleDayChange() {
    _dayTimer?.cancel();
    final now = _vietnamNow();
    final nextDay = DateTime.utc(now.year, now.month, now.day + 1);
    _dayTimer = Timer(nextDay.difference(now), _refreshDay);
  }

  void _refreshDay() {
    final now = _vietnamNow();
    final today = DateTime.utc(now.year, now.month, now.day);
    if (today != _today) {
      setState(() {
        final wasCurrentMonth = _year == _today.year && _month == _today.month;
        _today = today;
        if (wasCurrentMonth) {
          _year = today.year;
          _month = today.month;
          _selectedDate = null;
        }
        _loadRevision++;
        _calendar = widget.service.loadMonth(_year, _month);
      });
    }
    _scheduleDayChange();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshDay();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dayTimer?.cancel();
    super.dispose();
  }

  void _moveMonth(int delta) {
    final next = DateTime.utc(_year, _month + delta);
    if (next.isAfter(DateTime.utc(_today.year, _today.month))) return;
    setState(() {
      _year = next.year;
      _month = next.month;
      _selectedDate = null;
      _loadRevision++;
      _calendar = widget.service.loadMonth(_year, _month);
    });
  }

  void _reload() {
    setState(() {
      _loadRevision++;
      _calendar = widget.service.loadMonth(_year, _month);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final isCurrentMonth = _year == _today.year && _month == _today.month;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        // On phones the top bar already names the page (website docs 41).
        if (VnlfViewportSize.fromWidth(MediaQuery.sizeOf(context).width) !=
            VnlfViewportSize.mobile) ...[
          VnlfCenterPageHeader(title: vi.app.common.hoatDong),
          const SizedBox(height: 12),
        ],
        FutureBuilder<ActivityCalendarData>(
          key: ValueKey('$_year-$_month-$_loadRevision'),
          future: _calendar,
          builder: (context, snapshot) {
            final data = snapshot.data;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (data != null && !snapshot.hasError) ...[
                  _StreakHero(
                    streak: data.currentStreak,
                    longest: data.longestStreak,
                    colors: colors,
                  ),
                  const SizedBox(height: 12),
                ],
                if (_storageError) ...[
                  Semantics(
                    liveRegion: true,
                    child: Text(vi.app.activity.khongTheLuuTrang),
                  ),
                  OutlinedButton(
                    onPressed: _loadUncertainty,
                    child: Text(vi.app.activity.thuLaiLuuTru),
                  ),
                  const SizedBox(height: 12),
                ] else if (_checkingIn) ...[
                  FilledButton(
                    onPressed: null,
                    child: Text(vi.app.activity.dangDiemDanh),
                  ),
                  const SizedBox(height: 12),
                ] else if (_unconfirmed) ...[
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _checkInMessage == 'confirmed'
                          ? vi.app.activity.daXacNhanDiemDanh
                          : vi.app.activity.chuaXacNhanDuoc,
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _refreshingCheckIn || _checkingIn
                        ? null
                        : () => _refreshCheckIn(),
                    child: Text(vi.app.activity.lamMoiHoatDong),
                  ),
                  const SizedBox(height: 12),
                ] else if (!_loadingUncertainty &&
                    data != null &&
                    !snapshot.hasError &&
                    isCurrentMonth) ...[
                  FilledButton(
                    onPressed:
                        _checkingIn ||
                            data.days.any(
                              (day) => day.date == data.today && day.checkedIn,
                            )
                        ? null
                        : _checkIn,
                    child: Text(
                      _checkingIn
                          ? vi.app.activity.dangDiemDanh
                          : vi.app.activity.diemDanhHomNay,
                    ),
                  ),
                  if (_checkInMessage == 'confirmed')
                    Semantics(
                      liveRegion: true,
                      child: Text(vi.app.activity.daXacNhanDiem),
                    ),
                  const SizedBox(height: 12),
                ],
                _ActivityPanel(
                  colors: colors,
                  year: _year,
                  month: _month,
                  isCurrentMonth: isCurrentMonth,
                  onPrevious: () => _moveMonth(-1),
                  onNext: () => _moveMonth(1),
                  child: _calendarContent(snapshot, colors),
                ),
                if (data != null && !snapshot.hasError) ...[
                  const SizedBox(height: 12),
                  _TotalsPanel(data: data, colors: colors),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _calendarContent(
    AsyncSnapshot<ActivityCalendarData> snapshot,
    VnlfColors colors,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting &&
        !snapshot.hasData) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Semantics(
          liveRegion: true,
          child: Center(
            child: Column(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text(vi.app.activity.dangTaiHoatDong),
              ],
            ),
          ),
        ),
      );
    }
    if (snapshot.hasError) {
      return _ActivityError(
        message: vi.app.activity.khongTaiDuocHoat,
        retryLabel: vi.common.thuLai,
        onRetry: _reload,
      );
    }
    final data = snapshot.data;
    if (data == null || data.days.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 22),
        child: Text(
          vi.app.activity.chuaCoHoatDong,
          textAlign: TextAlign.center,
          style: VnlfTypography.body(colors.muted),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CalendarGrid(
          days: data.days,
          today:
              '${_today.year.toString().padLeft(4, '0')}-${_today.month.toString().padLeft(2, '0')}-${_today.day.toString().padLeft(2, '0')}',
          selectedDate: _selectedDate,
          colors: colors,
          onSelect: (date) => setState(() => _selectedDate = date),
        ),
        if (_selectedDate != null)
          _SelectedDay(
            day: data.days.firstWhere((day) => day.date == _selectedDate),
            today:
                '${_today.year.toString().padLeft(4, '0')}-${_today.month.toString().padLeft(2, '0')}-${_today.day.toString().padLeft(2, '0')}',
            colors: colors,
          ),
      ],
    );
  }
}

class _StreakHero extends StatelessWidget {
  const _StreakHero({
    required this.streak,
    required this.longest,
    required this.colors,
  });

  final int streak;
  final int longest;
  final VnlfColors colors;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: colors.brandSoft,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: colors.line),
    ),
    child: Row(
      children: [
        Icon(Icons.local_fire_department_outlined, color: colors.brand),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vi.app.activity.diemDanhMoiNgay,
                style: VnlfTypography.h2(colors.ink),
              ),
              const SizedBox(height: 4),
              Text(
                format(vi.app.activity.chuoiDaiNhatNgay, {'longest': longest}),
                style: VnlfTypography.meta(colors.muted),
              ),
            ],
          ),
        ),
        Semantics(
          label: format(vi.app.activity.chuoiNgay, {'streak': streak}),
          child: Column(
            children: [
              Text('$streak', style: VnlfTypography.number(colors.brand)),
              Text(
                vi.statsViews.ngay,
                style: VnlfTypography.meta(colors.muted),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ActivityPanel extends StatelessWidget {
  const _ActivityPanel({
    required this.colors,
    required this.year,
    required this.month,
    required this.isCurrentMonth,
    required this.onPrevious,
    required this.onNext,
    required this.child,
  });

  final VnlfColors colors;
  final int year;
  final int month;
  final bool isCurrentMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final monthLabel = format(vi.app.activity.thang, {
      'month': month,
      'year': year,
    });
    return _Panel(
      colors: colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                vi.statsViews.lichHoatDong,
                style: VnlfTypography.h2(colors.ink),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: vi.app.activity.thangTruoc,
                    onPressed: onPrevious,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Flexible(
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        monthLabel,
                        style: VnlfTypography.control(colors.ink),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: vi.app.activity.thangSau,
                    onPressed: isCurrentMonth ? null : onNext,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ],
          ),
          Text(
            vi.app.activity.ngayVaChuoiDiem,
            style: VnlfTypography.meta(colors.muted),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.days,
    required this.today,
    required this.selectedDate,
    required this.colors,
    this.selectable = true,
    required this.onSelect,
  });

  final List<ActivityDay> days;
  final String today;
  final String? selectedDate;
  final VnlfColors colors;
  final bool selectable;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    const weekdaysVi = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final first = DateTime.parse('${days.first.date}T00:00:00Z');
    final offset = first.weekday - 1;
    final cells = <ActivityDay?>[
      ...List<ActivityDay?>.filled(offset, null),
      ...days,
    ];
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final extent = math.max(
              48.0,
              MediaQuery.textScalerOf(context).scale(18) + 16,
            );
            const minimumWidth = 7 * 48.0 + 6 * 5;
            final calendar = SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: math.max(minimumWidth, constraints.maxWidth),
                child: Column(
                  children: [
                    Row(
                      children: [
                        for (final label in weekdaysVi)
                          Expanded(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 7),
                                child: Text(
                                  label,
                                  style: VnlfTypography.meta(colors.muted),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cells.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 5,
                        crossAxisSpacing: 5,
                        mainAxisExtent: extent,
                      ),
                      itemBuilder: (context, index) {
                        final day = cells[index];
                        if (day == null) return const SizedBox.shrink();
                        final future = day.date.compareTo(today) > 0;
                        final selected = day.date == selectedDate;
                        final hasPoints = day.points > 0;
                        final isToday = day.date == today;
                        final background = day.checkedIn
                            ? colors.brand
                            : hasPoints
                            ? colors.brandSoft
                            : colors.surfaceSoft;
                        final foreground = day.checkedIn
                            ? colors.paper
                            : colors.ink;
                        final label = _daySemantics(day, today);
                        return Semantics(
                          button: selectable,
                          label: label,
                          selected: selected,
                          enabled: !future && selectable,
                          child: Tooltip(
                            message: label,
                            child: OutlinedButton(
                              onPressed: future || !selectable
                                  ? null
                                  : () => onSelect(day.date),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                foregroundColor: foreground,
                                backgroundColor: background,
                                side: BorderSide(
                                  color: selected || isToday
                                      ? colors.brand
                                      : colors.line,
                                  width: selected || isToday ? 2 : 1,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                '${int.parse(day.date.substring(8, 10))}',
                                style: VnlfTypography.control(
                                  future ? colors.muted : foreground,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                calendar,
                if (constraints.maxWidth < minimumWidth)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      vi.app.activity.vuotNgangDeXem,
                      style: VnlfTypography.caption(colors.muted),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _LegendDot(
              color: colors.surfaceSoft,
              label: vi.activityCalendar.chuaDiemDanh,
              colors: colors,
            ),
            _LegendDot(
              color: colors.brand,
              label: vi.activityCalendar.daDiemDanh,
              colors: colors,
            ),
            _LegendDot(
              color: colors.brandSoft,
              label: vi.app.activity.coDiem,
              colors: colors,
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    required this.colors,
  });
  final Color color;
  final String label;
  final VnlfColors colors;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 11,
        height: 11,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: colors.line),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 4),
      Text(label, style: VnlfTypography.caption(colors.muted)),
    ],
  );
}

class _SelectedDay extends StatelessWidget {
  const _SelectedDay({
    required this.day,
    required this.today,
    required this.colors,
  });
  final ActivityDay day;
  final String today;
  final VnlfColors colors;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse('${day.date}T00:00:00Z');
    final dateLabel =
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
    final status = day.date.compareTo(today) > 0
        ? vi.app.activity.chuaDenNgay2
        : day.checkedIn
        ? format(vi.app.activity.daDiemDanhNgayThu, {
            'streakDay': day.streakDay,
          })
        : vi.activityCalendar.chuaDiemDanh;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Semantics(
        liveRegion: true,
        child: Text(
          '$dateLabel · $status · ${day.points} XP',
          style: VnlfTypography.body(colors.ink),
        ),
      ),
    );
  }
}

class _TotalsPanel extends StatelessWidget {
  const _TotalsPanel({required this.data, required this.colors});
  final ActivityCalendarData? data;
  final VnlfColors colors;

  @override
  Widget build(BuildContext context) => _Panel(
    colors: colors,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          vi.app.activity.diemTrongThang,
          style: VnlfTypography.h2(colors.ink),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _Total(
              label: vi.app.activity.tongDiem,
              value: data?.totalPoints,
              colors: colors,
            ),
            _Total(
              label: vi.app.activity.diemNhan,
              value: data?.earnedPoints,
              colors: colors,
            ),
            _Total(
              label: vi.app.activity.dieuChinh,
              value: data?.reversedPoints,
              colors: colors,
            ),
          ],
        ),
      ],
    ),
  );
}

class _Total extends StatelessWidget {
  const _Total({
    required this.label,
    required this.value,
    required this.colors,
  });
  final String label;
  final int? value;
  final VnlfColors colors;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: VnlfTypography.meta(colors.muted)),
        const SizedBox(height: 4),
        Text(value?.toString() ?? '—', style: VnlfTypography.h2(colors.ink)),
        Text('XP', style: VnlfTypography.caption(colors.muted)),
      ],
    ),
  );
}

class _ActivityError extends StatelessWidget {
  const _ActivityError({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 18),
    child: Column(
      children: [
        Semantics(
          liveRegion: true,
          child: Text(message, textAlign: TextAlign.center),
        ),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: onRetry, child: Text(retryLabel)),
      ],
    ),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.colors, required this.child});
  final VnlfColors colors;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: colors.paper,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: colors.line),
      boxShadow: [
        BoxShadow(
          color: colors.isDark ? Colors.black26 : const Color(0x0d101814),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ],
    ),
    child: child,
  );
}

String _daySemantics(ActivityDay day, String today) {
  final date = DateTime.parse('${day.date}T00:00:00Z');
  final dateLabel = '${date.day}/${date.month}/${date.year}';
  final state = day.date.compareTo(today) > 0
      ? vi.app.activity.chuaDenNgay
      : day.checkedIn
      ? format(vi.app.activity.daDiemDanhNgay, {'streakDay': day.streakDay})
      : vi.app.activity.chuaDiemDanh;
  return '$dateLabel, $state, ${day.points} XP';
}
