import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/appointment_model.dart';
import '../../../data/providers/other_providers.dart';
import '../../../data/providers/workspace_provider.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/avatar_stack.dart';

/// View modes for the calendar screen header.
enum _CalendarView { day, month }

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen>
    with SingleTickerProviderStateMixin {
  late DateTime _selectedDate;
  late ScrollController _dateScrollController;
  _CalendarView _view = _CalendarView.day;

  // Controls the fade animation between views
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _dateScrollController = ScrollController();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..value = 1.0;
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Sync provider with initial date AFTER build — avoids writing inside build()
      ref.read(selectedDateProvider.notifier).state = _selectedDate;
      ref.read(viewedMonthProvider.notifier).state = _selectedDate;
      // Scroll to today's date cell in day view
      final targetOffset = (DateTime.now().day - 1) * 64.0;
      if (_dateScrollController.hasClients) {
        try {
          final maxExtent = _dateScrollController.position.maxScrollExtent;
          _dateScrollController.animateTo(
            targetOffset > maxExtent ? maxExtent : targetOffset,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } catch (_) {}
      }
    });
  }

  @override
  void dispose() {
    _dateScrollController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  /// Updates the selected date in both local state and the Riverpod provider.
  /// Never write to providers inside build() — always use this method.
  void _selectDate(DateTime date) {
    setState(() => _selectedDate = date);
    ref.read(selectedDateProvider.notifier).state = date;
  }

  /// Switches the calendar view and plays a fade transition.
  Future<void> _switchView(_CalendarView newView) async {
    await _fadeCtrl.reverse();
    setState(() => _view = newView);
    _fadeCtrl.forward();
  }

  /// Navigates the month-grid view by [delta] months (−1 or +1).
  void _navigateMonth(int delta) {
    final current = ref.read(viewedMonthProvider);
    final next = DateTime(current.year, current.month + delta, 1);
    ref.read(viewedMonthProvider.notifier).state = next;
  }

  List<DateTime> get _datesInSelectedMonth {
    final firstDay = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final lastDay = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    return List.generate(lastDay.day, (i) => firstDay.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    // DO NOT write to providers here. Use _selectDate() and _navigateMonth().
    final appointments = ref.watch(dayAppointmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ─── Header ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('My Calendar', style: AppTextStyles.displaySmall),
                            Text(
                              DateFormat('MMMM d, yyyy').format(_selectedDate),
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Monthly view toggle button
                        GestureDetector(
                          onTap: () => _switchView(
                            _view == _CalendarView.day
                                ? _CalendarView.month
                                : _CalendarView.day,
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: _view == _CalendarView.month
                                  ? AppColors.primary
                                  : AppColors.surface,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2))
                              ],
                            ),
                            child: Icon(
                              Icons.calendar_month_rounded,
                              color: _view == _CalendarView.month
                                  ? Colors.white
                                  : AppColors.primary,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _showCalendarSettings(context),
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.surface, shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2))
                              ],
                            ),
                            child: const Icon(Icons.more_horiz_rounded,
                                color: AppColors.textPrimary, size: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ─── Animated View Area (Day Strip or Month Grid) ──
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: _view == _CalendarView.day
                          ? _buildDayStrip()
                          : _buildMonthGrid(),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          // ─── Day Timeline ─────────────────────────────────────────
          if (_view == _CalendarView.day)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: appointments.isEmpty
                  ? SliverFillRemaining(
                      child: EmptyState(
                        icon: Icons.event_outlined,
                        title: 'No Appointments',
                        subtitle: 'No appointments scheduled for this day.',
                        actionLabel: 'Add Appointment',
                        onAction: () => _showAddAppointment(context),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _AppointmentTimelineTile(
                            appointment: appointments[i]),
                        childCount: appointments.length,
                      ),
                    ),
            )
          else
            const SliverToBoxAdapter(child: SizedBox.shrink()),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAppointment(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  // ─── Day Strip (horizontal scroll) ─────────────────────────────────────────

  Widget _buildDayStrip() {
    return Column(
      children: [
        _WeekDayLabels(selectedDate: _selectedDate),
        const SizedBox(height: 10),
        SizedBox(
          height: 72,
          child: ListView.builder(
            controller: _dateScrollController,
            scrollDirection: Axis.horizontal,
            itemCount: _datesInSelectedMonth.length,
            itemBuilder: (context, i) {
              final date = _datesInSelectedMonth[i];
              final isSelected = date.day == _selectedDate.day &&
                  date.month == _selectedDate.month;
              final isToday = date.day == DateTime.now().day &&
                  date.month == DateTime.now().month &&
                  date.year == DateTime.now().year;
              return _DateCell(
                date: date,
                isSelected: isSelected,
                isToday: isToday,
                onTap: () => _selectDate(date),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── Month Grid ─────────────────────────────────────────────────────────────

  Widget _buildMonthGrid() {
    final viewedMonth = ref.watch(viewedMonthProvider);
    final monthAppts = ref.watch(monthAppointmentsProvider);

    // Build a set of days that have appointments for quick lookup
    final daysWithAppts = <int>{};
    for (final a in monthAppts) {
      if (a.startTime.year == viewedMonth.year &&
          a.startTime.month == viewedMonth.month) {
        daysWithAppts.add(a.startTime.day);
      }
    }

    final firstDay = DateTime(viewedMonth.year, viewedMonth.month, 1);
    final lastDay = DateTime(viewedMonth.year, viewedMonth.month + 1, 0);
    // Weekday of first day: Monday=1 … Sunday=7. We use 0-indexed (Mon=0).
    final startOffset = (firstDay.weekday - 1) % 7;
    final totalCells = startOffset + lastDay.day;
    // Round up to full weeks
    final gridCellCount = ((totalCells / 7).ceil()) * 7;

    return Column(
      children: [
        // Month navigation row
        Row(
          children: [
            GestureDetector(
              onTap: () => _navigateMonth(-1),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.chevron_left_rounded,
                    color: AppColors.textPrimary),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  DateFormat('MMMM yyyy').format(viewedMonth),
                  style: AppTextStyles.titleLarge,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _navigateMonth(1),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Weekday header row
        Row(
          children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
              .map((d) => Expanded(
                    child: Center(
                      child: Text(d,
                          style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textTertiary,
                              fontWeight: FontWeight.w700)),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),

        // Calendar grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.0,
          ),
          itemCount: gridCellCount,
          itemBuilder: (context, index) {
            final dayNum = index - startOffset + 1;

            // Empty cell (before month start or after month end)
            if (dayNum < 1 || dayNum > lastDay.day) {
              return const SizedBox.shrink();
            }

            final date = DateTime(viewedMonth.year, viewedMonth.month, dayNum);
            final isSelected = date.day == _selectedDate.day &&
                date.month == _selectedDate.month &&
                date.year == _selectedDate.year;
            final isToday = date.day == DateTime.now().day &&
                date.month == DateTime.now().month &&
                date.year == DateTime.now().year;
            final hasAppointment = daysWithAppts.contains(dayNum);

            return GestureDetector(
              onTap: () {
                // Selecting a day in month view: update selected date,
                // sync selectedDateProvider, and switch back to day view.
                _selectDate(date);
                _switchView(_CalendarView.day);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.purpleGradient : null,
                  color: isSelected
                      ? null
                      : isToday
                          ? AppColors.primary.withOpacity(0.08)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: isToday && !isSelected
                      ? Border.all(
                          color: AppColors.primary.withOpacity(0.4), width: 1.5)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$dayNum',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: isSelected
                            ? Colors.white
                            : isToday
                                ? AppColors.primary
                                : AppColors.textPrimary,
                        fontWeight: isToday || isSelected
                            ? FontWeight.w800
                            : FontWeight.w500,
                      ),
                    ),
                    if (hasAppointment) ...[
                      const SizedBox(height: 3),
                      Container(
                        width: 5, height: 5,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white70
                              : AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showAddAppointment(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) =>
          _AddAppointmentSheet(parentRef: ref, date: _selectedDate),
    );
  }

  void _showCalendarSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => const _CalendarSettingsSheet(),
    );
  }
}

// ─── Week Day Labels (for day strip) ─────────────────────────────────────────

class _WeekDayLabels extends StatelessWidget {
  final DateTime selectedDate;

  const _WeekDayLabels({required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days
          .map((d) => SizedBox(
                width: 32,
                child: Center(
                    child: Text(d,
                        style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.textTertiary,
                            fontWeight: FontWeight.w600))),
              ))
          .toList(),
    );
  }
}

// ─── Date Cell (day strip item) ───────────────────────────────────────────────

class _DateCell extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  const _DateCell({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.purpleGradient : null,
          color: isSelected
              ? null
              : isToday
                  ? AppColors.primary.withOpacity(0.08)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isToday && !isSelected
              ? Border.all(
                  color: AppColors.primary.withOpacity(0.3), width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat('E').format(date).substring(0, 1),
              style: AppTextStyles.labelSmall.copyWith(
                color: isSelected ? Colors.white70 : AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${date.day}',
              style: AppTextStyles.headlineSmall.copyWith(
                color: isSelected
                    ? Colors.white
                    : isToday
                        ? AppColors.primary
                        : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Appointment Timeline Tile ────────────────────────────────────────────────

class _AppointmentTimelineTile extends StatelessWidget {
  final AppointmentModel appointment;

  const _AppointmentTimelineTile({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time column
          SizedBox(
            width: 56,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormat('hh:mm').format(appointment.startTime),
                  style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700),
                ),
                Text(
                  DateFormat('a').format(appointment.startTime),
                  style: AppTextStyles.labelSmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Appointment card
          Expanded(
            child: AnimatedCard(
              child: Row(
                children: [
                  Container(
                    width: 4, height: 60,
                    decoration: BoxDecoration(
                      color: Color(appointment.colorValue),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(appointment.title,
                            style: AppTextStyles.titleMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(
                          '${DateFormat('hh:mm a').format(appointment.startTime)} - ${DateFormat('hh:mm a').format(appointment.endTime)}',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: Color(appointment.colorValue)),
                        ),
                      ],
                    ),
                  ),
                  if (appointment.attendeeIds.isNotEmpty)
                    AvatarStack(names: appointment.attendeeIds, size: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Add Appointment Sheet ────────────────────────────────────────────────────

class _AddAppointmentSheet extends StatefulWidget {
  final WidgetRef parentRef;
  final DateTime date;

  const _AddAppointmentSheet({required this.parentRef, required this.date});

  @override
  State<_AddAppointmentSheet> createState() => _AddAppointmentSheetState();
}

class _AddAppointmentSheetState extends State<_AddAppointmentSheet> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  int _colorIndex = 0;

  final List<Color> _colors = [
    AppColors.primary, AppColors.accentBlue, AppColors.accentGreen,
    AppColors.accentOrange, AppColors.accentPink, AppColors.accentTeal,
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('New Appointment', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 16),
            Row(
                children: _colors.asMap().entries.map((entry) {
              final i = entry.key;
              final c = entry.value;
              return GestureDetector(
                onTap: () => setState(() => _colorIndex = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: c, shape: BoxShape.circle,
                    border: _colorIndex == i
                        ? Border.all(color: AppColors.textPrimary, width: 2.5)
                        : null,
                  ),
                ),
              );
            }).toList()),
            const SizedBox(height: 14),
            TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                    hintText: 'Title',
                    prefixIcon: Icon(Icons.event_rounded,
                        color: AppColors.primary))),
            const SizedBox(height: 12),
            TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                    hintText: 'Location (optional)',
                    prefixIcon: Icon(Icons.location_on_rounded,
                        color: AppColors.primary))),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: GestureDetector(
                  onTap: () async {
                    final t = await showTimePicker(
                        context: context, initialTime: _startTime);
                    if (t != null) setState(() => _startTime = t);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      const Icon(Icons.access_time_rounded,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Text(_startTime.format(context),
                          style: AppTextStyles.titleMedium),
                    ]),
                  ),
                )),
                const SizedBox(width: 12),
                Expanded(
                    child: GestureDetector(
                  onTap: () async {
                    final t = await showTimePicker(
                        context: context, initialTime: _endTime);
                    if (t != null) setState(() => _endTime = t);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      const Icon(Icons.access_time_filled_rounded,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Text(_endTime.format(context),
                          style: AppTextStyles.titleMedium),
                    ]),
                  ),
                )),
              ],
            ),
            const SizedBox(height: 24),
            GradientButton(
                label: 'Schedule Appointment',
                onTap: () {
                  if (_titleController.text.trim().isEmpty) return;
                  final workspaceId =
                      widget.parentRef.read(activeWorkspaceIdProvider);
                  if (workspaceId == null) return;
                  final start = DateTime(
                      widget.date.year, widget.date.month, widget.date.day,
                      _startTime.hour, _startTime.minute);
                  final end = DateTime(
                      widget.date.year, widget.date.month, widget.date.day,
                      _endTime.hour, _endTime.minute);
                  final appointment = AppointmentModel.create(
                    workspaceId: workspaceId,
                    title: _titleController.text.trim(),
                    startTime: start,
                    endTime: end,
                    location: _locationController.text.trim(),
                    colorValue: _colors[_colorIndex].value,
                  );
                  widget.parentRef
                      .read(appointmentsProvider.notifier)
                      .add(appointment);
                  Navigator.pop(context);
                }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── Calendar Settings Sheet ──────────────────────────────────────────────────

class _CalendarSettingsSheet extends StatelessWidget {
  const _CalendarSettingsSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Calendar Settings', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.sync_rounded, color: AppColors.primary),
            title: const Text('Sync with Google Calendar'),
            trailing: Switch(value: true, onChanged: (v) {}),
            contentPadding: EdgeInsets.zero,
          ),
          ListTile(
            leading: const Icon(Icons.notifications_active_rounded, color: AppColors.primary),
            title: const Text('Default Reminders'),
            subtitle: const Text('15 minutes before'),
            trailing: const Icon(Icons.chevron_right_rounded),
            contentPadding: EdgeInsets.zero,
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.schedule_rounded, color: AppColors.primary),
            title: const Text('Working Hours'),
            subtitle: const Text('9:00 AM - 5:00 PM'),
            trailing: const Icon(Icons.chevron_right_rounded),
            contentPadding: EdgeInsets.zero,
            onTap: () {},
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
