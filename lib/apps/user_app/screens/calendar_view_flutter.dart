import 'package:flutter/material.dart';

class CalendarViewFlutter extends StatefulWidget {
  const CalendarViewFlutter({super.key});

  @override
  State<CalendarViewFlutter> createState() => _CalendarViewFlutterState();
}

class _CalendarViewFlutterState extends State<CalendarViewFlutter> {
  late final DateTime _today;
  late DateTime _activeMonth;
  late final List<_CalendarEvent> _events;

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    _activeMonth = DateTime(_today.year, _today.month, 1);
    _events = [
      _CalendarEvent(DateTime(_today.year, _today.month, 2), '판교 IT센터'),
      _CalendarEvent(DateTime(_today.year, _today.month, 7), '서초 아파트 재건축'),
      _CalendarEvent(DateTime(_today.year, _today.month, 21), '성수동 리모델링'),
      _CalendarEvent(DateTime(_today.year, _today.month + 1, 5), '하남 신축 현장'),
      _CalendarEvent(DateTime(_today.year, _today.month - 1, 26), '송파 상가 공사'),
    ];
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  String _twoDigit(int value) => value.toString().padLeft(2, '0');

  void _goToPreviousMonth() {
    setState(() {
      _activeMonth = DateTime(_activeMonth.year, _activeMonth.month - 1, 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _activeMonth = DateTime(_activeMonth.year, _activeMonth.month + 1, 1);
    });
  }

  void _jumpToToday() {
    setState(() {
      _activeMonth = DateTime(_today.year, _today.month, 1);
    });
  }

  List<_CalendarEvent> _eventsForDay(DateTime day) {
    return _events.where((event) => _isSameDay(event.date, day)).toList();
  }

  List<_CalendarEvent> _eventsForMonth(DateTime month) {
    final list = _events.where((event) => _isSameMonth(event.date, month)).toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  void _showEventSheet(BuildContext context, DateTime date, List<_CalendarEvent> events) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${date.year}.${_twoDigit(date.month)}.${_twoDigit(date.day)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 20, color: Color(0xFFCBD5F5)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...events.map(
                  (event) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2937),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF374151)),
                    ),
                    child: Row(
                      children: [
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0xFFF59E0B),
                            shape: BoxShape.circle,
                          ),
                          child: SizedBox(width: 8, height: 8),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            event.title,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthStart = DateTime(_activeMonth.year, _activeMonth.month, 1);
    final monthEnd = DateTime(_activeMonth.year, _activeMonth.month + 1, 0);
    final leadingEmpty = monthStart.weekday % 7;
    final totalDays = monthEnd.day;
    const weeksInView = 6;
    const gridChildAspectRatio = 0.9;
    final gridAspectRatio = (7 * gridChildAspectRatio) / weeksInView;
    final cellCount = weeksInView * 7;
    final isCurrentMonth = _isSameMonth(_activeMonth, _today);
    final monthlyEvents = _eventsForMonth(_activeMonth);

    return LayoutBuilder(
      builder: (context, constraints) {
        return ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF374151)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: _goToPreviousMonth,
                      icon: const Icon(Icons.chevron_left, color: Color(0xFFCBD5F5)),
                      splashRadius: 20,
                    ),
                    Expanded(
                      child: Text(
                        '${_activeMonth.year}년 ${_activeMonth.month}월',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: _goToNextMonth,
                      icon: const Icon(Icons.chevron_right, color: Color(0xFFCBD5F5)),
                      splashRadius: 20,
                    ),
                    const SizedBox(width: 6),
                    TextButton(
                      onPressed: _jumpToToday,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFCBD5F5),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        backgroundColor: const Color(0xFF0F172A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        side: const BorderSide(color: Color(0xFF334155)),
                      ),
                      child: Text(isCurrentMonth ? '이번달' : '오늘', style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: const [
                    _WeekdayLabel('일', color: Color(0xFFF87171)),
                    _WeekdayLabel('월'),
                    _WeekdayLabel('화'),
                    _WeekdayLabel('수'),
                    _WeekdayLabel('목'),
                    _WeekdayLabel('금'),
                    _WeekdayLabel('토', color: Color(0xFF60A5FA)),
                  ],
                ),
                const SizedBox(height: 8),
                AspectRatio(
                  aspectRatio: gridAspectRatio,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      childAspectRatio: gridChildAspectRatio,
                    ),
                    itemCount: cellCount,
                    itemBuilder: (context, index) {
                      if (index < leadingEmpty || index >= leadingEmpty + totalDays) {
                        return const SizedBox.shrink();
                      }

                      final day = index - leadingEmpty + 1;
                      final date = DateTime(_activeMonth.year, _activeMonth.month, day);
                      final isToday = _isSameDay(date, _today);
                      final dayEvents = _eventsForDay(date);
                      final hasEvent = dayEvents.isNotEmpty;
                      final weekdayIndex = index % 7;
                      final textColor = weekdayIndex == 0
                          ? const Color(0xFFF87171)
                          : weekdayIndex == 6
                              ? const Color(0xFF60A5FA)
                              : Colors.white;

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: hasEvent ? () => _showEventSheet(context, date, dayEvents) : null,
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: isToday ? const Color(0xFF0B1220) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: isToday ? Border.all(color: const Color(0xFFF59E0B)) : null,
                            ),
                            child: Stack(
                              children: [
                                Align(
                                  alignment: Alignment.topCenter,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      '$day',
                                      style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
                                    ),
                                  ),
                                ),
                                if (hasEvent)
                                  const Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Padding(
                                      padding: EdgeInsets.only(bottom: 6),
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: Color(0xFFF59E0B),
                                          shape: BoxShape.circle,
                                        ),
                                        child: SizedBox(width: 6, height: 6),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isCurrentMonth ? '이번 달 일정' : '${_activeMonth.month}월 일정',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                if (monthlyEvents.isEmpty)
                  const Text('등록된 일정이 없습니다.', style: TextStyle(color: Color(0xFF94A3B8))),
                if (monthlyEvents.isNotEmpty)
                  Column(
                    children: monthlyEvents
                        .map(
                          (event) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _EventRow(
                              date: '${_twoDigit(event.date.month)}/${_twoDigit(event.date.day)}',
                              title: event.title,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label, {this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color ?? const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }
}

class _CalendarEvent {
  const _CalendarEvent(this.date, this.title);

  final DateTime date;
  final String title;
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.date, required this.title});

  final String date;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Text(date, style: const TextStyle(fontSize: 12, color: Color(0xFFCBD5F5))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
