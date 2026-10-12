import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/appointment_model.dart';
import '../../../data/providers/calendar_settings_provider.dart';
import '../../../data/providers/other_providers.dart';
import '../../../data/providers/workspace_provider.dart';
import '../../../core/service/notification.dart';
import '../../dashboard/dashboard_navigation_provider.dart';
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
    ref.read(viewedMonthProvider.notifier).state =
        DateTime(date.year, date.month, 1);
  }

  /// Switches the calendar view and plays a fade transition.
  Future<void> _switchView(_CalendarView newView) async {
    if (newView == _CalendarView.month) {
      ref.read(viewedMonthProvider.notifier).state =
          DateTime(_selectedDate.year, _selectedDate.month, 1);
    }
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
                        IconButton(
                          onPressed: () {
                            ref.read(dashboardTabIndexProvider.notifier).state =
                                0;
                            context.go('/home');
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          icon: const Icon(
                            Icons.arrow_back_ios_rounded,
                            size: 20,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('My Calendar',
                                style: AppTextStyles.displaySmall),
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
                            width: 40,
                            height: 40,
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
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
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

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: appointments.isEmpty
                ? SliverFillRemaining(
                    child: EmptyState(
                      icon: Icons.event_outlined,
                      title: 'No Appointments',
                      subtitle: 'No appointments scheduled for this day.',
                      actionLabel: 'Add Appointment',
                      onAction: () => _openAddAppointment(context),
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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'calendarScreenFab',
        onPressed: () => _openAddAppointment(context),
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
    final dayAppointmentCount = <int, int>{};
    for (final a in monthAppts) {
      final monthStart = DateTime(viewedMonth.year, viewedMonth.month, 1);
      final monthEnd =
          DateTime(viewedMonth.year, viewedMonth.month + 1, 0, 23, 59, 59, 999);
      final start = a.startTime;
      final end = a.endTime;

      if (start.isAfter(monthEnd) || end.isBefore(monthStart)) continue;

      var cursor = DateTime(start.year, start.month, start.day);
      final finish = DateTime(end.year, end.month, end.day);

      while (!cursor.isAfter(finish)) {
        if (cursor.year == viewedMonth.year &&
            cursor.month == viewedMonth.month) {
          dayAppointmentCount[cursor.day] =
              (dayAppointmentCount[cursor.day] ?? 0) + 1;
        }
        cursor = cursor.add(const Duration(days: 1));
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
                width: 36,
                height: 36,
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
                width: 36,
                height: 36,
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
            final appointmentCount = dayAppointmentCount[dayNum] ?? 0;
            final hasAppointment = appointmentCount > 0;

            return GestureDetector(
              onTap: () {
                _selectDate(date);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(2),
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.purpleGradient : null,
                  color: isSelected
                      ? null
                      : hasAppointment
                          ? AppColors.primary.withOpacity(0.08)
                          : isToday
                              ? AppColors.primary.withOpacity(0.08)
                              : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: isToday && !isSelected
                      ? Border.all(
                          color: AppColors.primary.withOpacity(0.4), width: 1.5)
                      : hasAppointment && !isSelected
                          ? Border.all(
                              color: AppColors.primary.withOpacity(0.2),
                              width: 1,
                            )
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withOpacity(0.2)
                              : AppColors.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$appointmentCount',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isSelected ? Colors.white : Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
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

  /// Opens the full-screen Add Appointment page for the selected date.
  void _openAddAppointment(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddAppointmentScreen(date: _selectedDate),
      ),
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
                    width: 4,
                    height: 60,
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
                          style: AppTextStyles.bodySmall
                              .copyWith(color: Color(appointment.colorValue)),
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

// ─── Add Appointment Screen (full page) ───────────────────────────────────────

/// Full-screen "New Appointment" page.
/// Opened from the FAB and from the "Add Appointment" button in the empty state.
class AddAppointmentScreen extends ConsumerStatefulWidget {
  final DateTime date;

  const AddAppointmentScreen({super.key, required this.date});

  @override
  ConsumerState<AddAppointmentScreen> createState() =>
      _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends ConsumerState<AddAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  int _colorIndex = 0;
  bool _isSaving = false;

  final List<Color> _colors = [
    AppColors.primary,
    AppColors.accentBlue,
    AppColors.accentGreen,
    AppColors.accentOrange,
    AppColors.accentPink,
    AppColors.accentTeal,
  ];

  @override
  void initState() {
    super.initState();
    final settings = ref.read(calendarSettingsProvider);
    _startTime = settings.workStart;
    final startMinutes = _startTime.hour * 60 + _startTime.minute + 60;
    final normalized = startMinutes % (24 * 60);
    _endTime = TimeOfDay(
      hour: normalized ~/ 60,
      minute: normalized % 60,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final t = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (t == null) return;
    setState(() {
      if (isStart) {
        _startTime = t;
      } else {
        _endTime = t;
      }
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a workspace before scheduling.')),
      );
      
      return;
    }

    final settings = ref.read(calendarSettingsProvider);
    final start = DateTime(
      widget.date.year,
      widget.date.month,
      widget.date.day,
      _startTime.hour,
      _startTime.minute,
    );
    final end = DateTime(
      widget.date.year,
      widget.date.month,
      widget.date.day,
      _endTime.hour,
      _endTime.minute,
    );
    if (!end.isAfter(start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time must be later than start time.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    final workStartMinutes =
        settings.workStart.hour * 60 + settings.workStart.minute;
    final workEndMinutes = settings.workEnd.hour * 60 + settings.workEnd.minute;
    final outsideWorkingHours =
        startMinutes < workStartMinutes || endMinutes > workEndMinutes;

    final messenger = ScaffoldMessenger.of(context);

    if (outsideWorkingHours) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Outside your working hours.')),
      );
    }

    setState(() => _isSaving = true);

    try {
      final appointment = AppointmentModel.create(
        workspaceId: workspaceId,
        title: _titleController.text.trim(),
        startTime: start,
        endTime: end,
        location: _locationController.text.trim(),
        colorValue: _colors[_colorIndex].value,
      );
      await ref.read(appointmentsProvider.notifier).add(appointment);

      // Schedule alarm-style reminder using the "Default Reminders" setting.
      await NotificationService.scheduleAppointmentReminder(
        seed: '$workspaceId${appointment.title}',
        title: appointment.title,
        start: start,
        reminderMinutes: settings.reminderMinutes,
        location: _locationController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Appointment scheduled successfully.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Unable to schedule appointment: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _timeBox({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.labelSmall),
                  Text(value, style: AppTextStyles.titleMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_rounded,
              size: 20, color: AppColors.textPrimary),
        ),
        title: Text('New Appointment', style: AppTextStyles.headlineSmall),
        centerTitle: false,
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selected date
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            color: AppColors.primary, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          DateFormat('EEEE, dd MMM yyyy').format(widget.date),
                          style: AppTextStyles.titleMedium
                              .copyWith(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Color', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 10),
                  Row(
                    children: _colors.asMap().entries.map((entry) {
                      final i = entry.key;
                      final c = entry.value;
                      return GestureDetector(
                        onTap: () => setState(() => _colorIndex = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 10),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: _colorIndex == i
                                ? Border.all(
                                    color: AppColors.textPrimary, width: 2.5)
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _titleController,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Title',
                      prefixIcon:
                          Icon(Icons.event_rounded, color: AppColors.primary),
                    ),
                    validator: (value) {
                      final title = (value ?? '').trim();
                      if (title.isEmpty) {
                        return 'Appointment title is required.';
                      }
                      if (title.length > 20) {
                        return 'Appointment title must be 20 characters or less.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _locationController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'Location (optional)',
                      prefixIcon: Icon(Icons.location_on_rounded,
                          color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _timeBox(
                          icon: Icons.access_time_rounded,
                          label: 'Start',
                          value: _startTime.format(context),
                          onTap: () => _pickTime(isStart: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _timeBox(
                          icon: Icons.access_time_filled_rounded,
                          label: 'End',
                          value: _endTime.format(context),
                          onTap: () => _pickTime(isStart: false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  GradientButton(
                    label: _isSaving ? 'Scheduling...' : 'Schedule Appointment',
                    onTap: _save,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Calendar Settings Sheet ──────────────────────────────────────────────────

class _CalendarSettingsSheet extends ConsumerWidget {
  const _CalendarSettingsSheet();

  String _formatReminder(int minutes) {
    if (minutes <= 0) return 'No reminder';
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '$hours hour${hours > 1 ? 's' : ''}';
    return '$hours hour${hours > 1 ? 's' : ''} $mins min';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(calendarSettingsProvider);

    Future<void> pickReminder() async {
      final selected = await showDialog<int>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Default reminder'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<int>(
                  value: 0,
                  groupValue: settings.reminderMinutes,
                  title: const Text('No reminder'),
                  onChanged: (value) => Navigator.pop(dialogContext, value),
                ),
                RadioListTile<int>(
                  value: 5,
                  groupValue: settings.reminderMinutes,
                  title: const Text('5 minutes'),
                  onChanged: (value) => Navigator.pop(dialogContext, value),
                ),
                RadioListTile<int>(
                  value: 10,
                  groupValue: settings.reminderMinutes,
                  title: const Text('10 minutes'),
                  onChanged: (value) => Navigator.pop(dialogContext, value),
                ),
                RadioListTile<int>(
                  value: 15,
                  groupValue: settings.reminderMinutes,
                  title: const Text('15 minutes'),
                  onChanged: (value) => Navigator.pop(dialogContext, value),
                ),
                RadioListTile<int>(
                  value: 30,
                  groupValue: settings.reminderMinutes,
                  title: const Text('30 minutes'),
                  onChanged: (value) => Navigator.pop(dialogContext, value),
                ),
                RadioListTile<int>(
                  value: 60,
                  groupValue: settings.reminderMinutes,
                  title: const Text('1 hour'),
                  onChanged: (value) => Navigator.pop(dialogContext, value),
                ),
              ],
            ),
          ),
        ),
      );

      if (selected == null || !context.mounted) return;
      await ref.read(calendarSettingsProvider.notifier).setReminder(selected);
    }

    Future<void> pickWorkingHours() async {
      final startTime = await showTimePicker(
        context: context,
        initialTime: settings.workStart,
      );
      if (startTime == null || !context.mounted) return;

      final endTime = await showTimePicker(
        context: context,
        initialTime: settings.workEnd,
      );
      if (endTime == null || !context.mounted) return;

      final startMinutes = startTime.hour * 60 + startTime.minute;
      final endMinutes = endTime.hour * 60 + endTime.minute;

      if (endMinutes <= startMinutes) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Work end time must be later than work start time.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      await ref
          .read(calendarSettingsProvider.notifier)
          .setWorkingHours(startTime, endTime);
    }

    return Padding(
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
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Calendar Settings', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 20),
          // ListTile(
          //   leading: const Icon(Icons.sync_rounded, color: AppColors.primary),
          //   title: const Text('Sync with Google Calendar'),
          //   trailing: Switch(
          //     value: settings.syncGoogle,
          //     onChanged: (value) async {
          //       await ref
          //           .read(calendarSettingsProvider.notifier)
          //           .setSync(value);
          //     },
          //   ),
          //   contentPadding: EdgeInsets.zero,
          // ),
          ListTile(
            leading: const Icon(Icons.notifications_active_rounded,
                color: AppColors.primary),
            title: const Text('Default Reminders'),
            subtitle: Text(_formatReminder(settings.reminderMinutes)),
            trailing: const Icon(Icons.chevron_right_rounded),
            contentPadding: EdgeInsets.zero,
            onTap: pickReminder,
          ),
          ListTile(
            leading:
                const Icon(Icons.schedule_rounded, color: AppColors.primary),
            title: const Text('Working Hours'),
            subtitle: Text(
                '${settings.workStart.format(context)} - ${settings.workEnd.format(context)}'),
            trailing: const Icon(Icons.chevron_right_rounded),
            contentPadding: EdgeInsets.zero,
            onTap: pickWorkingHours,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}