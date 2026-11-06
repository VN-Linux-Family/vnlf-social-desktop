import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../domain/activity_models.dart';
import '../domain/activity_service.dart';

/// Native personal activity view. The parent supplies the session-bound
/// service so route and account lifecycle wiring remain app-owned.
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key, required this.service});

  final ActivityService service;

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
    final english = Localizations.localeOf(context).languageCode == 'en';
    final colors = VnlfColors.of(context);
    final year = int.parse(acknowledgment.date.substring(0, 4));
    final month = int.parse(acknowledgment.date.substring(5, 7));
    final checkins = {for (final day in acknowledgment.checkins) day.date: day.streakDay};
    final range = activityMonthRange(year, month);
    final days = <ActivityDay>[];
    for (var date = range.from; date.compareTo(range.to) <= 0; date = shiftActivityDay(date, 1)) {
      days.add(ActivityDay(
        date: date,
        points: 0,
        checkedIn: checkins.containsKey(date),
        streakDay: checkins[date] ?? 0,
      ));
    }

    return AlertDialog(
      title: Text(english ? 'Daily check-in' : 'Điểm danh hàng ngày'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              english
                  ? 'You checked in for ${acknowledgment.currentStreak} days in a row.'
                  : 'Bạn đã điểm danh ${acknowledgment.currentStreak} ngày liên tiếp.',
              style: VnlfTypography.body(colors.ink),
            ),
            const SizedBox(height: 16),
            _CalendarGrid(
              days: days,
              today: acknowledgment.date,
              selectedDate: null,
              english: english,
              colors: colors,
              selectable: false,
              onSelect: (_) {},
            ),
          ],
        ),
      ),
      actions: [
        if (onViewActivity != null)
          TextButton(
            onPressed: onViewActivity,
            child: Text(english ? 'View activity' : 'Xem lịch hoạt động'),
          ),
        FilledButton(
          onPressed: onContinue ?? () => Navigator.of(context).pop(),
          child: Text(english ? 'Continue' : 'Tiếp tục'),
        ),
      ],
    );
  }
}

class _ActivityScreenState extends State<ActivityScreen> {
  late final DateTime _today;
  late int _year;
  late int _month;
  String? _selectedDate;
  late Future<ActivityCalendarData> _calendar;
  int _loadRevision = 0;

  @override
  void didUpdateWidget(covariant ActivityScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.service != widget.service) {
      _loadRevision++;
      _calendar = widget.service.loadMonth(_year, _month);
    }
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    _today = DateTime.utc(now.year, now.month, now.day);
    _year = now.year;
    _month = now.month;
    _calendar = widget.service.loadMonth(_year, _month);
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
    final english = Localizations.localeOf(context).languageCode == 'en';
    final colors = VnlfColors.of(context);
    final isCurrentMonth = _year == _today.year && _month == _today.month;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        VnlfCenterPageHeader(
          title: english ? 'Activity' : 'Hoạt động',
        ),
        const SizedBox(height: 12),
        FutureBuilder<ActivityCalendarData>(
          key: ValueKey('$_year-$_month-$_loadRevision'),
          future: _calendar,
          builder: (context, snapshot) {
            final data = snapshot.data;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StreakHero(
                  streak: data?.currentStreak ?? 0,
                  longest: data?.longestStreak ?? 0,
                  english: english,
                  colors: colors,
                ),
                const SizedBox(height: 12),
                _ActivityPanel(
                  colors: colors,
                  english: english,
                  year: _year,
                  month: _month,
                  isCurrentMonth: isCurrentMonth,
                  onPrevious: () => _moveMonth(-1),
                  onNext: () => _moveMonth(1),
                  child: _calendarContent(snapshot, english, colors),
                ),
                const SizedBox(height: 12),
                _TotalsPanel(data: data, english: english, colors: colors),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _calendarContent(
    AsyncSnapshot<ActivityCalendarData> snapshot,
    bool english,
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
                Text(english ? 'Loading activity…' : 'Đang tải hoạt động…'),
              ],
            ),
          ),
        ),
      );
    }
    if (snapshot.hasError) {
      return _ActivityError(
        message: english
            ? 'Could not load activity for this month.'
            : 'Không tải được hoạt động trong tháng này.',
        retryLabel: english ? 'Retry' : 'Thử lại',
        onRetry: _reload,
      );
    }
    final data = snapshot.data;
    if (data == null || data.days.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 22),
        child: Text(
          english ? 'No activity in this period.' : 'Chưa có hoạt động.',
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
          today: data.today,
          selectedDate: _selectedDate,
          english: english,
          colors: colors,
          onSelect: (date) => setState(() => _selectedDate = date),
        ),
        if (_selectedDate != null)
          _SelectedDay(
            day: data.days.firstWhere((day) => day.date == _selectedDate),
            today: data.today,
            english: english,
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
    required this.english,
    required this.colors,
  });

  final int streak;
  final int longest;
  final bool english;
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
                english ? 'Daily check-in' : 'Điểm danh mỗi ngày',
                style: VnlfTypography.h2(colors.ink),
              ),
              const SizedBox(height: 4),
              Text(
                english
                    ? 'Longest streak: $longest days'
                    : 'Chuỗi dài nhất: $longest ngày',
                style: VnlfTypography.meta(colors.muted),
              ),
            ],
          ),
        ),
        Semantics(
          label: english ? '$streak day streak' : 'Chuỗi $streak ngày',
          child: Column(
            children: [
              Text('$streak', style: VnlfTypography.h1(colors.brand)),
              Text(english ? 'days' : 'ngày', style: VnlfTypography.meta(colors.muted)),
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
    required this.english,
    required this.year,
    required this.month,
    required this.isCurrentMonth,
    required this.onPrevious,
    required this.onNext,
    required this.child,
  });

  final VnlfColors colors;
  final bool english;
  final int year;
  final int month;
  final bool isCurrentMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final monthLabel = english
        ? '${_englishMonths[month - 1]} $year'
        : 'Tháng $month, $year';
    return _Panel(
      colors: colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  english ? 'Activity calendar' : 'Lịch hoạt động',
                  style: VnlfTypography.h2(colors.ink),
                ),
              ),
              IconButton(
                tooltip: english ? 'Previous month' : 'Tháng trước',
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left),
              ),
              Semantics(
                liveRegion: true,
                child: Text(monthLabel, style: VnlfTypography.control(colors.ink)),
              ),
              IconButton(
                tooltip: english ? 'Next month' : 'Tháng sau',
                onPressed: isCurrentMonth ? null : onNext,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          Text(
            english
                ? 'Dates and streaks use Vietnam time (UTC+07).'
                : 'Ngày và chuỗi điểm danh theo giờ Việt Nam (UTC+07).',
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
    required this.english,
    required this.colors,
    this.selectable = true,
    required this.onSelect,
  });

  final List<ActivityDay> days;
  final String today;
  final String? selectedDate;
  final bool english;
  final VnlfColors colors;
  final bool selectable;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    const weekdaysVi = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    const weekdaysEn = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
    final first = DateTime.parse('${days.first.date}T00:00:00Z');
    final offset = first.weekday - 1;
    final cells = <ActivityDay?>[
      ...List<ActivityDay?>.filled(offset, null),
      ...days,
    ];
    return Column(
      children: [
        Row(
          children: [
            for (final label in english ? weekdaysEn : weekdaysVi)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Text(label, style: VnlfTypography.meta(colors.muted)),
                  ),
                ),
              ),
          ],
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cells.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 5,
            crossAxisSpacing: 5,
            childAspectRatio: 1.15,
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
            final foreground = day.checkedIn ? colors.paper : colors.ink;
            final label = _daySemantics(day, today, english);
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
                      color: selected || isToday ? colors.brand : colors.line,
                      width: selected || isToday ? 2 : 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    '${int.parse(day.date.substring(8, 10))}',
                    style: VnlfTypography.control(future ? colors.muted : foreground),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _LegendDot(color: colors.surfaceSoft, label: english ? 'No check-in' : 'Chưa điểm danh', colors: colors),
            _LegendDot(color: colors.brand, label: english ? 'Checked in' : 'Đã điểm danh', colors: colors),
            _LegendDot(color: colors.brandSoft, label: english ? 'Earned points' : 'Có điểm', colors: colors),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label, required this.colors});
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
  const _SelectedDay({required this.day, required this.today, required this.english, required this.colors});
  final ActivityDay day;
  final String today;
  final bool english;
  final VnlfColors colors;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse('${day.date}T00:00:00Z');
    final dateLabel = '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
    final status = day.date.compareTo(today) > 0
        ? (english ? 'Not yet' : 'Chưa đến ngày')
        : day.checkedIn
        ? (english ? 'Checked in, streak day ${day.streakDay}' : 'Đã điểm danh, ngày thứ ${day.streakDay}')
        : (english ? 'Not checked in' : 'Chưa điểm danh');
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
  const _TotalsPanel({required this.data, required this.english, required this.colors});
  final ActivityCalendarData? data;
  final bool english;
  final VnlfColors colors;

  @override
  Widget build(BuildContext context) => _Panel(
    colors: colors,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(english ? 'Points this month' : 'Điểm trong tháng', style: VnlfTypography.h2(colors.ink)),
        const SizedBox(height: 12),
        Row(
          children: [
            _Total(label: english ? 'Total' : 'Tổng điểm', value: data?.totalPoints, colors: colors),
            _Total(label: english ? 'Earned' : 'Điểm nhận', value: data?.earnedPoints, colors: colors),
            _Total(label: english ? 'Adjusted' : 'Điều chỉnh', value: data?.reversedPoints, colors: colors),
          ],
        ),
      ],
    ),
  );
}

class _Total extends StatelessWidget {
  const _Total({required this.label, required this.value, required this.colors});
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
  const _ActivityError({required this.message, required this.retryLabel, required this.onRetry});
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

const _englishMonths = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

String _daySemantics(ActivityDay day, String today, bool english) {
  final date = DateTime.parse('${day.date}T00:00:00Z');
  final dateLabel = english
      ? '${_englishMonths[date.month - 1]} ${date.day}, ${date.year}'
      : '${date.day}/${date.month}/${date.year}';
  final state = day.date.compareTo(today) > 0
      ? (english ? 'not yet' : 'chưa đến ngày')
      : day.checkedIn
      ? (english ? 'checked in, streak day ${day.streakDay}' : 'đã điểm danh, ngày thứ ${day.streakDay}')
      : (english ? 'not checked in' : 'chưa điểm danh');
  return '$dateLabel, $state, ${day.points} XP';
}
