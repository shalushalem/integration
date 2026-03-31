import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:myapp/services/appwrite_service.dart';
import 'package:myapp/services/backend_service.dart';
import 'package:myapp/theme/theme_tokens.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const ScheduleApp());
}

class ScheduleApp extends StatelessWidget {
  const ScheduleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Schedule / Calendar',
      debugShowCheckedModeBanner: false,
      home: CalendarShell(),
    );
  }
}

// ==========================================
// MODELS
// ==========================================
class PlanItem {
  String? id;
  final String occasion;
  final IconData icon;
  final String colorTheme;
  final String time;
  final String outfit;
  final DateTime dateTime;
  bool hasReminder;

  PlanItem({
    this.id,
    required this.occasion,
    required this.icon,
    this.colorTheme = 'orange',
    this.time = '',
    this.outfit = '',
    DateTime? dateTime,
    this.hasReminder = true,
  }) : dateTime = dateTime ?? DateTime.now();
}

class _OccasionOption {
  final String name;
  final IconData icon;

  const _OccasionOption({
    required this.name,
    required this.icon,
  });
}

const List<_OccasionOption> _fallbackOccasionOptions = [
  _OccasionOption(name: 'Gym', icon: Icons.fitness_center),
  _OccasionOption(name: 'Office', icon: Icons.work_outline),
  _OccasionOption(name: 'Party', icon: Icons.celebration),
  _OccasionOption(name: 'Shopping', icon: Icons.shopping_bag_outlined),
  _OccasionOption(name: 'Study', icon: Icons.menu_book),
  _OccasionOption(name: 'Travel', icon: Icons.flight_takeoff),
  _OccasionOption(name: 'Event', icon: Icons.event),
  _OccasionOption(name: 'Date Night', icon: Icons.favorite_border),
];

String _dateKey(DateTime date) => '${date.year}-${date.month}-${date.day}';

String _colorThemeForOccasion(String occasion) {
  final text = occasion.toLowerCase();
  if (text.contains('office') ||
      text.contains('work') ||
      text.contains('study') ||
      text.contains('travel')) {
    return 'blue';
  }
  if (text.contains('party') ||
      text.contains('date') ||
      text.contains('event') ||
      text.contains('wedding')) {
    return 'pink';
  }
  return 'orange';
}

IconData _iconForOccasion(String occasion) {
  final text = occasion.toLowerCase();
  if (text.contains('gym') || text.contains('workout')) {
    return Icons.fitness_center;
  }
  if (text.contains('office') || text.contains('work')) {
    return Icons.work_outline;
  }
  if (text.contains('party')) {
    return Icons.celebration;
  }
  if (text.contains('shopping')) {
    return Icons.shopping_bag_outlined;
  }
  if (text.contains('study') || text.contains('exam')) {
    return Icons.menu_book;
  }
  if (text.contains('travel') || text.contains('trip') || text.contains('vacation')) {
    return Icons.flight_takeoff;
  }
  if (text.contains('date')) {
    return Icons.favorite_border;
  }
  return Icons.event;
}

String _formatPlanTime(DateTime dateTime) {
  final tod = TimeOfDay.fromDateTime(dateTime);
  final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
  final minute = tod.minute.toString().padLeft(2, '0');
  final suffix = tod.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour:$minute $suffix';
}

// ==========================================
// MAIN SHELL
// ==========================================
class CalendarShell extends StatefulWidget {
  const CalendarShell({Key? key}) : super(key: key);

  @override
  State<CalendarShell> createState() => _CalendarShellState();
}

class _CalendarShellState extends State<CalendarShell> {
  DateTime _currentMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();

  Map<String, List<PlanItem>> _plansData = <String, List<PlanItem>>{};
  List<_OccasionOption> _occasionOptions = _fallbackOccasionOptions;
  bool _isLoadingPlans = true;

  bool _isChatOpen = false;
  String _activeOccasion = 'Gym';
  IconData _activeIcon = Icons.fitness_center;

  // Helper formats
  String get _selectedDateKey => _dateKey(_selectedDate);
  String get _todayKey => _dateKey(DateTime.now());

  @override
  void initState() {
    super.initState();
    _loadPlansFromBackend();
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value is DateTime) return value.toLocal();
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true).toLocal();
    }
    if (value is String && value.trim().isNotEmpty) {
      try {
        return DateTime.parse(value).toLocal();
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  bool _toBool(dynamic value, {bool fallback = true}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final text = value.trim().toLowerCase();
      if (text == 'true' || text == '1' || text == 'yes') return true;
      if (text == 'false' || text == '0' || text == 'no') return false;
    }
    return fallback;
  }

  List<_OccasionOption> _buildDynamicOccasionOptions(Set<String> source) {
    final normalized = source
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toSet();
    if (normalized.isEmpty) return _fallbackOccasionOptions;

    final options = <_OccasionOption>[];
    final seen = <String>{};

    for (final item in _fallbackOccasionOptions) {
      final match = normalized.firstWhere(
        (name) => name.toLowerCase() == item.name.toLowerCase(),
        orElse: () => '',
      );
      if (match.isNotEmpty) {
        options.add(_OccasionOption(name: match, icon: item.icon));
        seen.add(match.toLowerCase());
      }
    }

    final extras = normalized.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    for (final name in extras) {
      final key = name.toLowerCase();
      if (seen.contains(key)) continue;
      options.add(_OccasionOption(name: name, icon: _iconForOccasion(name)));
      seen.add(key);
    }

    return options.isEmpty ? _fallbackOccasionOptions : options;
  }

  void _insertPlanLocally(PlanItem plan) {
    final key = _dateKey(plan.dateTime);
    _plansData.putIfAbsent(key, () => <PlanItem>[]);
    _plansData[key]!.add(plan);
    _plansData[key]!.sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  PlanItem? _planFromDoc(ProxyDocument doc) {
    final data = doc.data;
    final dateTime = _parseDateTime(
      data['dateTime'] ?? data['date_time'] ?? data['datetime'],
    );
    if (dateTime == null) return null;

    final occasionRaw = (data['occasion'] ?? data['title'] ?? 'Event').toString();
    final occasion = occasionRaw.trim().isEmpty ? 'Event' : occasionRaw.trim();
    final outfit = (data['outfitDescription'] ?? data['outfit'] ?? '').toString().trim();
    final storedTime = (data['time'] ?? '').toString().trim();

    return PlanItem(
      id: doc.$id,
      occasion: occasion,
      icon: _iconForOccasion(occasion),
      colorTheme: _colorThemeForOccasion(occasion),
      time: storedTime.isEmpty ? _formatPlanTime(dateTime) : storedTime,
      outfit: outfit,
      hasReminder: _toBool(data['reminder'], fallback: true),
      dateTime: dateTime,
    );
  }

  Future<void> _loadPlansFromBackend() async {
    final appwrite = context.read<AppwriteService>();
    try {
      final docs = await appwrite.getUserPlans();
      final loaded = <String, List<PlanItem>>{};
      final occasionSet = <String>{};

      for (final doc in docs) {
        final parsed = _planFromDoc(doc);
        if (parsed == null) continue;
        final key = _dateKey(parsed.dateTime);
        loaded.putIfAbsent(key, () => <PlanItem>[]).add(parsed);
        occasionSet.add(parsed.occasion);
      }
      for (final list in loaded.values) {
        list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      }

      if (!mounted) return;
      final options = _buildDynamicOccasionOptions(occasionSet);
      setState(() {
        _plansData = loaded;
        _occasionOptions = options;
        _activeOccasion = options.first.name;
        _activeIcon = options.first.icon;
        _isLoadingPlans = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _occasionOptions = _fallbackOccasionOptions;
        _activeOccasion = _fallbackOccasionOptions.first.name;
        _activeIcon = _fallbackOccasionOptions.first.icon;
        _isLoadingPlans = false;
      });
    }
  }

  void _changeMonth(int increment) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + increment, 1);
    });
  }

  void _addPlan(PlanItem plan) {
    setState(() {
      _insertPlanLocally(plan);
      final hasOccasion = _occasionOptions.any(
        (opt) => opt.name.toLowerCase() == plan.occasion.toLowerCase(),
      );
      if (!hasOccasion) {
        _occasionOptions = [
          ..._occasionOptions,
          _OccasionOption(name: plan.occasion, icon: _iconForOccasion(plan.occasion)),
        ];
      }
    });

    unawaited(_persistPlan(plan));
  }

  Future<void> _persistPlan(PlanItem plan) async {
    final appwrite = context.read<AppwriteService>();
    try {
      final doc = await appwrite.createPlan({
        'occasion': plan.occasion,
        'outfitDescription': plan.outfit,
        'dateTime': plan.dateTime.toUtc().toIso8601String(),
        'time': plan.time,
        'reminder': plan.hasReminder,
      });
      if (!mounted) return;
      setState(() {
        plan.id = doc.$id;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Saved locally. Cloud sync failed.'),
          backgroundColor: context.themeTokens.backgroundSecondary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _removePlan(int index) {
    unawaited(_removePlanAsync(index));
  }

  Future<void> _removePlanAsync(int index) async {
    final list = _plansData[_selectedDateKey];
    if (list == null || index < 0 || index >= list.length) return;

    final removed = list[index];
    setState(() {
      list.removeAt(index);
      if (list.isEmpty) {
        _plansData.remove(_selectedDateKey);
      }
    });

    if (removed.id == null) return;
    final appwrite = context.read<AppwriteService>();
    try {
      await appwrite.deletePlan(removed.id!);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Plan removed locally. Cloud delete failed.'),
          backgroundColor: context.themeTokens.backgroundSecondary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _toggleReminder(int index) {
    unawaited(_toggleReminderAsync(index));
  }

  Future<void> _toggleReminderAsync(int index) async {
    final list = _plansData[_selectedDateKey];
    if (list == null || index < 0 || index >= list.length) return;

    final plan = list[index];
    final previous = plan.hasReminder;
    setState(() {
      plan.hasReminder = !plan.hasReminder;
    });

    if (plan.id == null) return;
    final appwrite = context.read<AppwriteService>();
    try {
      await appwrite.updatePlanReminder(plan.id!, plan.hasReminder);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        plan.hasReminder = previous;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Reminder update failed.'),
          backgroundColor: context.themeTokens.backgroundSecondary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _openChat(String occasion, IconData icon) {
    setState(() {
      _activeOccasion = occasion;
      _activeIcon = icon;
      _isChatOpen = true;
    });
  }

  void _closeChat() {
    setState(() {
      _isChatOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.themeTokens;
    return Scaffold(
      backgroundColor: theme.backgroundSecondary,
      body: Stack(
        children: [
          const BackgroundScene(),
          SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _isChatOpen 
                      ? StyleChatScreen(
                          key: const ValueKey('chat'),
                          occasion: _activeOccasion,
                          icon: _activeIcon,
                          onBack: _closeChat,
                          onSavePlan: (time, outfit) {
                            final mergedDate = DateTime(
                              _selectedDate.year,
                              _selectedDate.month,
                              _selectedDate.day,
                              time.hour,
                              time.minute,
                            );
                            _addPlan(PlanItem(
                              occasion: _activeOccasion,
                              icon: _activeIcon,
                              time: _formatPlanTime(mergedDate),
                              outfit: outfit,
                              colorTheme: _colorThemeForOccasion(_activeOccasion),
                              hasReminder: true,
                              dateTime: mergedDate,
                            ));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Plan saved to calendar!',
                                  style: TextStyle(
                                    color: context.themeTokens.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                backgroundColor: context.themeTokens.backgroundSecondary,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        )
                      : MainCalendarView(
                          key: const ValueKey('calendar'),
                          currentMonth: _currentMonth,
                          selectedDate: _selectedDate,
                          todayKey: _todayKey,
                          selectedDateKey: _selectedDateKey,
                          plans: _plansData[_selectedDateKey] ?? [],
                          allPlansData: _plansData,
                          isLoading: _isLoadingPlans,
                          onMonthChanged: _changeMonth,
                          onDaySelected: (date) {
                            setState(() {
                              _selectedDate = date;
                            });
                          },
                          onAddPlanPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (ctx) => AddPlanModal(
                                options: _occasionOptions,
                                onChatOpened: (occ, emo) {
                                  Navigator.pop(ctx);
                                  _openChat(occ, emo);
                                },
                              ),
                            );
                          },
                          onRemovePlan: _removePlan,
                          onToggleReminder: _toggleReminder,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// BACKGROUND EFFECTS
// ==========================================
class BackgroundScene extends StatefulWidget {
  const BackgroundScene({Key? key}) : super(key: key);

  @override
  State<BackgroundScene> createState() => _BackgroundSceneState();
}

class _BackgroundSceneState extends State<BackgroundScene> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.themeTokens;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Stack(
          children: [
            // Container matching the fallback background
            Container(color: theme.backgroundSecondary),
            /* 
             * Uncomment the below code to add the animated orbs back.
             * The reference CSS had them hidden so they are omitted for a cleaner look.
             */
            /*
            Positioned(
              top: -100 + (_ctrl.value * 40),
              left: -140 + (_ctrl.value * 60),
              child: _buildOrb(480, theme.accent.primary.withOpacity(0.15)),
            ),
            Positioned(
              top: 260 + (_ctrl.value * -30),
              right: -100 + (_ctrl.value * 40),
              child: _buildOrb(360, theme.accent.secondary.withOpacity(0.15)),
            ),
            Positioned(
              bottom: 60 + (_ctrl.value * 50),
              left: 10 + (_ctrl.value * -30),
              child: _buildOrb(300, theme.accent.tertiary.withOpacity(0.15)),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: Container(color: Colors.transparent),
              ),
            ),
            */
          ],
        );
      },
    );
  }

  Widget _buildOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

// ==========================================
// MAIN CALENDAR VIEW
// ==========================================
class MainCalendarView extends StatelessWidget {
  final DateTime currentMonth;
  final DateTime selectedDate;
  final String todayKey;
  final String selectedDateKey;
  final List<PlanItem> plans;
  final Map<String, List<PlanItem>> allPlansData;
  final bool isLoading;
  final Function(int) onMonthChanged;
  final Function(DateTime) onDaySelected;
  final VoidCallback onAddPlanPressed;
  final Function(int) onRemovePlan;
  final Function(int) onToggleReminder;

  MainCalendarView({
    Key? key,
    required this.currentMonth,
    required this.selectedDate,
    required this.todayKey,
    required this.selectedDateKey,
    required this.plans,
    required this.allPlansData,
    required this.isLoading,
    required this.onMonthChanged,
    required this.onDaySelected,
    required this.onAddPlanPressed,
    required this.onRemovePlan,
    required this.onToggleReminder,
  }) : super(key: key);

  final List<String> _months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
  final List<String> _weekdays = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];

  @override
  Widget build(BuildContext context) {
    final theme = context.themeTokens;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      children: [
        // Top Header
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.maybePop(context);
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(right: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.card,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: theme.accent.primary.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 2))],
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 6.0),
                  child: Icon(Icons.arrow_back_ios, size: 18, color: theme.textPrimary),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Schedule / Calendar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.textPrimary)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(color: theme.accent.tertiary, shape: BoxShape.circle, boxShadow: [BoxShadow(color: theme.accent.tertiary.withOpacity(0.75), blurRadius: 7)]),
                      ),
                      const SizedBox(width: 6),
                      Text('${getAllPlansCount()} outfit plans', style: TextStyle(fontSize: 12, color: theme.mutedText)),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
        const SizedBox(height: 18),

        // Calendar Box
        Container(
          decoration: BoxDecoration(
            color: theme.card,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: theme.textPrimary.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              // Month Nav
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _navBtn(Icons.chevron_left_rounded, () => onMonthChanged(-1), theme),
                    Text('${_months[currentMonth.month - 1]} ${currentMonth.year}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: theme.textPrimary)),
                    _navBtn(Icons.chevron_right_rounded, () => onMonthChanged(1), theme),
                  ],
                ),
              ),

              // Days Strip
              SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: (() {
                    final now = DateTime.now();
                    final isCurrentMonth = currentMonth.year == now.year && currentMonth.month == now.month;
                    final totalDays = _daysInMonth(currentMonth);
                    return isCurrentMonth ? (totalDays - now.day + 1) : totalDays;
                  })(),
                  itemBuilder: (ctx, index) {
                    final now = DateTime.now();
                    final isCurrentMonth = currentMonth.year == now.year && currentMonth.month == now.month;
                    final day = isCurrentMonth ? (now.day + index) : (index + 1);
                    final date = DateTime(currentMonth.year, currentMonth.month, day);
                    final key = "${date.year}-${date.month}-${date.day}";
                    final isSelected = key == selectedDateKey;
                    final isToday = key == todayKey;
                    final hasEvent = (allPlansData[key]?.isNotEmpty ?? false);

                    return GestureDetector(
                      onTap: () => onDaySelected(date),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                        width: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: theme.card,
                          border: Border.all(color: isSelected ? theme.accent.primary : Colors.transparent, width: isSelected ? 1.5 : 1),
                          boxShadow: isSelected ? [BoxShadow(color: theme.accent.primary.withOpacity(0.6), blurRadius: 16, spreadRadius: 2)] : [],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (isToday)
                               Positioned(top: 6, right: 6, child: Container(width: 5, height: 5, decoration: BoxDecoration(color: theme.accent.tertiary, shape: BoxShape.circle))),
                            if (hasEvent)
                               Positioned(bottom: 6, child: Container(width: 5, height: 5, decoration: BoxDecoration(color: theme.accent.secondary, shape: BoxShape.circle))),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_weekdays[date.weekday % 7], style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isSelected ? theme.accent.primary : theme.mutedText)),
                                const SizedBox(height: 2),
                                Text('$day', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: theme.textPrimary)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 14), color: theme.textPrimary.withOpacity(0.06)),

              // Plans Section
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(selectedDateKey == todayKey ? "Today's Plans" : "${_months[selectedDate.month - 1]} ${selectedDate.day} Plans", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.mutedText, letterSpacing: 1.2)),
                    const SizedBox(height: 10),
                    
                    if (isLoading)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 22),
                        child: Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.accent.primary,
                            ),
                          ),
                        ),
                      )
                    else if (plans.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text("Nothing planned 🌿\nTap 'Add a Plan' below", textAlign: TextAlign.center, style: TextStyle(color: theme.mutedText, fontSize: 13, height: 1.5)),
                      )
                    else 
                      ...List.generate(plans.length, (idx) {
                        final plan = plans[idx];
                        Color sideColor = theme.accent.primary;
                        List<Color> bgGrad = [theme.accent.primary.withOpacity(0.13), theme.accent.primary.withOpacity(0.07)];
                        
                        if(plan.colorTheme == 'blue') {
                          sideColor = theme.accent.secondary;
                          bgGrad = [theme.accent.secondary.withOpacity(0.12), theme.accent.secondary.withOpacity(0.06)];
                        } else if (plan.colorTheme == 'pink') {
                          sideColor = theme.accent.tertiary;
                          bgGrad = [theme.accent.tertiary.withOpacity(0.12), theme.accent.tertiary.withOpacity(0.06)];
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(colors: bgGrad, begin: Alignment.topLeft, end: Alignment.bottomRight),
                            border: Border(left: BorderSide(color: sideColor, width: 4)),
                            boxShadow: [BoxShadow(color: sideColor.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(13, 9, 40, 9),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(plan.icon, size: 16, color: theme.textPrimary),
                                    const SizedBox(height: 2),
                                    Text(plan.occasion, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: theme.textPrimary)),
                                    const SizedBox(height: 2),
                                    Text(plan.time.isEmpty ? 'Planned' : plan.time, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.mutedText)),
                                    if (plan.outfit.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(plan.outfit, style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: theme.textPrimary.withOpacity(0.8))),
                                    ]
                                  ],
                                ),
                              ),
                              Positioned(
                                top: 4, right: 4,
                                child: IconButton(
                                  icon: Icon(Icons.close, size: 14, color: theme.mutedText),
                                  onPressed: () => onRemovePlan(idx),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                ),
                              ),
                              Positioned(
                                bottom: 4, right: 4,
                                child: IconButton(
                                  icon: Icon(plan.hasReminder ? Icons.notifications_active : Icons.notifications_off, size: 14, color: plan.hasReminder ? theme.accent.primary : theme.mutedText),
                                  onPressed: () => onToggleReminder(idx),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                ),
                              )
                            ],
                          ),
                        );
                      }),
                    
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: onAddPlanPressed,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [theme.accent.primary, theme.accent.secondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [BoxShadow(color: theme.accent.primary.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 4))],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline, size: 16, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Add a Plan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 80), // Padding
      ],
    );
  }

  Widget _navBtn(IconData icon, VoidCallback onTap, dynamic theme) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: theme.backgroundSecondary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: theme.textPrimary),
      ),
    );
  }

  int _daysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  int getAllPlansCount() {
    int total = 0;
    allPlansData.values.forEach((l) => total += l.length);
    return total;
  }
}

// ==========================================
// ADD PLAN MODAL
// ==========================================
class AddPlanModal extends StatefulWidget {
  final List<_OccasionOption> options;
  final Function(String, IconData) onChatOpened;

  const AddPlanModal({
    Key? key,
    required this.options,
    required this.onChatOpened,
  }) : super(key: key);

  @override
  State<AddPlanModal> createState() => _AddPlanModalState();
}

class _AddPlanModalState extends State<AddPlanModal> {
  String? _selectedOccasion;

  @override
  void initState() {
    super.initState();
    if (widget.options.isNotEmpty) {
      _selectedOccasion = widget.options.first.name;
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = context.themeTokens;
    return Container(
      decoration: BoxDecoration(
        color: theme.backgroundSecondary,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
        boxShadow: [BoxShadow(color: theme.textPrimary.withOpacity(0.08), blurRadius: 32, offset: const Offset(0, -4))],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: theme.cardBorder, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 18),
          
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('New Plan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.textPrimary)),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: theme.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: theme.cardBorder)),
                  child: Row(
                    children: [
                      Icon(Icons.close, size: 14, color: theme.mutedText),
                      SizedBox(width: 4),
                      Text('Close', style: TextStyle(color: theme.mutedText, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 16),

          // Occasions grid
          Text('CHOOSE OCCASION', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: theme.mutedText)),
          const SizedBox(height: 10),
          if (widget.options.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Text(
                'No occasion history yet. Add a plan from chat to get started.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.mutedText,
                  height: 1.4,
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.options.map((option) {
                final isSel =
                    _selectedOccasion?.toLowerCase() == option.name.toLowerCase();
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedOccasion = option.name;
                    });
                    widget.onChatOpened(option.name, option.icon);
                  },
                  child: Container(
                    width: (MediaQuery.of(context).size.width - 40 - 24) / 4,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSel ? theme.accent.primary.withOpacity(0.2) : theme.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSel ? theme.accent.primary : theme.cardBorder,
                      ),
                      boxShadow: isSel
                          ? [
                              BoxShadow(
                                color: theme.accent.primary.withOpacity(0.4),
                                blurRadius: 12,
                              ),
                            ]
                          : [],
                    ),
                    child: Column(
                      children: [
                        Icon(option.icon, size: 24, color: theme.textPrimary),
                        const SizedBox(height: 4),
                        Text(
                          option.name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSel ? theme.accent.primary : theme.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// ==========================================
// CHAT SCREEN
// ==========================================
class ChatMessage {
  final String text;
  final bool isUser;
  final String time;
  ChatMessage(this.text, {required this.isUser, required this.time});
}

class StyleChatScreen extends StatefulWidget {
  final String occasion;
  final IconData icon;
  final VoidCallback onBack;
  final Function(TimeOfDay, String) onSavePlan;

  const StyleChatScreen({Key? key, required this.occasion, required this.icon, required this.onBack, required this.onSavePlan}) : super(key: key);

  @override
  State<StyleChatScreen> createState() => _StyleChatScreenState();
}

class _StyleChatScreenState extends State<StyleChatScreen> {
  final TextEditingController _textCtrl = TextEditingController();
  final List<ChatMessage> _msgs = [];
  final List<Map<String, String>> _chatHistory = [];
  bool _isListening = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    final intro = "Hi! I'm your style assistant for ${widget.occasion}. Ask me what to wear!";
    _msgs.add(ChatMessage(intro, isUser: false, time: 'Now'));
    _chatHistory.add({'role': 'assistant', 'content': intro});
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  TimeOfDay? _extractTimeOfDay(String text) {
    final regex = RegExp(
      r"\b(\d{1,2})(?::(\d{2}))?\s*(am|pm|a\.m\.|p\.m\.|o'clock)?\b",
      caseSensitive: false,
    );
    final match = regex.firstMatch(text);
    if (match == null) return null;

    final rawHour = int.tryParse(match.group(1) ?? '');
    if (rawHour == null || rawHour < 0 || rawHour > 23) return null;
    final rawMinute = int.tryParse(match.group(2) ?? '0') ?? 0;
    if (rawMinute < 0 || rawMinute > 59) return null;

    final marker = (match.group(3) ?? '').toLowerCase().replaceAll('.', '');
    var hour = rawHour;
    if (marker == 'am' || marker == "o'clock") {
      if (hour == 12) hour = 0;
    } else if (marker == 'pm') {
      if (hour < 12) hour += 12;
    }

    if (hour > 23) return null;
    return TimeOfDay(hour: hour, minute: rawMinute);
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final suffix = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $suffix';
  }

  String _extractOutfitSummary(String text) {
    final cleaned = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.isEmpty) {
      return 'Styled look for ${widget.occasion}.';
    }
    final firstSentence = cleaned.split(RegExp(r'[.!?]')).first.trim();
    if (firstSentence.isEmpty) {
      return 'Styled look for ${widget.occasion}.';
    }
    if (firstSentence.length > 120) {
      return '${firstSentence.substring(0, 120).trim()}...';
    }
    return firstSentence;
  }

  Future<String> _fetchAiStylingReply(String userText) async {
    final backend = context.read<BackendService>();
    final appwrite = context.read<AppwriteService>();

    var userId = 'calendar_guest';
    try {
      final user = await appwrite.getCurrentUser();
      if (user != null) userId = user.$id;
    } catch (_) {}

    final result = await backend.sendChatQuery(
      userText,
      userId,
      List<Map<String, String>>.from(_chatHistory),
      '',
      moduleContext: 'calendar_style_${widget.occasion}',
    );

    if (result['error'] != null) {
      return "I couldn't reach styling AI right now. Try again in a moment.";
    }

    final rawMessage = result['message'];
    if (rawMessage is Map<String, dynamic>) {
      final text = (rawMessage['content'] ?? '').toString().trim();
      if (text.isNotEmpty) return text;
    }
    if (rawMessage is String && rawMessage.trim().isNotEmpty) {
      return rawMessage.trim();
    }

    final fallback = (result['content'] ?? '').toString().trim();
    if (fallback.isNotEmpty) return fallback;
    return "Let's style your ${widget.occasion.toLowerCase()} look.";
  }

  Future<void> _sendMsg() async {
    final userText = _textCtrl.text.trim();
    if (userText.isEmpty || _isSending) return;

    setState(() {
      _msgs.add(ChatMessage(userText, isUser: true, time: 'Now'));
      _textCtrl.clear();
      _isSending = true;
    });
    _chatHistory.add({'role': 'user', 'content': userText});

    final lower = userText.toLowerCase();
    final wantsSave = lower.contains('yes') ||
        lower.contains('save') ||
        lower.contains('add') ||
        lower.contains('reminder');
    final extractedTime = _extractTimeOfDay(userText);

    String aiText = await _fetchAiStylingReply(userText);
    final summary = _extractOutfitSummary(aiText);

    if (extractedTime != null) {
      final reminderAt = _formatTimeOfDay(extractedTime);
      widget.onSavePlan(extractedTime, summary);
      aiText =
          '$aiText\n\nSaved this plan with a reminder at $reminderAt.';
    } else if (wantsSave) {
      aiText =
          '$aiText\n\nTell me the reminder time (for example, 7:30 pm) and I will save it.';
    }

    if (!mounted) return;
    setState(() {
      _msgs.add(ChatMessage(aiText, isUser: false, time: 'Now'));
      _isSending = false;
    });
    _chatHistory.add({'role': 'assistant', 'content': aiText});
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.themeTokens;
    return WillPopScope(
      onWillPop: () async {
        widget.onBack();
        return false;
      },
      child: Container(
        color: theme.backgroundSecondary,
        child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 28, 18, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: widget.onBack,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 40, height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.card,
                      border: Border.all(color: theme.cardBorder),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6.0),
                      child: Icon(Icons.arrow_back_ios, size: 18, color: theme.textPrimary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Text('${widget.occasion} Chat', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: theme.textPrimary)),
                       Container(margin: const EdgeInsets.only(top: 5, bottom: 4), width: 36, height: 2.5, decoration: BoxDecoration(color: theme.accent.primary, borderRadius: BorderRadius.circular(2))),
                       Row(
                         children: [
                           Container(width: 6, height: 6, decoration: BoxDecoration(color: theme.accent.tertiary, shape: BoxShape.circle, boxShadow: [BoxShadow(color: theme.accent.tertiary, blurRadius: 6)])),
                           const SizedBox(width: 6),
                           Text('Ask anything about your outfit.', style: TextStyle(fontSize: 13, color: theme.mutedText))
                         ],
                       )
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Chat list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              itemCount: _msgs.length,
              itemBuilder: (ctx, i) {
                final m = _msgs[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: m.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!m.isUser)
                        Container(
                          width: 28, height: 28, margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(color: theme.card, border: Border.all(color: theme.cardBorder), shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: Icon(widget.icon, size: 14, color: theme.textPrimary),
                        ),
                      
                      Column(
                        crossAxisAlignment: m.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Container(
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.card,
                              border: Border.all(color: theme.cardBorder),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(18),
                                topRight: const Radius.circular(18),
                                bottomLeft: Radius.circular(m.isUser ? 18 : 5),
                                bottomRight: Radius.circular(m.isUser ? 5 : 18),
                              ),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 2))],
                            ),
                            child: Text(m.text, style: TextStyle(color: theme.textPrimary, fontSize: 13.5)),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                            child: Text(m.time, style: TextStyle(fontSize: 10, color: theme.mutedText)),
                          )
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
            child: Column(
              children: [
                 // Suggestion Chips
                 SingleChildScrollView(
                   scrollDirection: Axis.horizontal,
                   child: Row(
                     children: [
                       _chip('What should I wear?', theme),
                       _chip('Casual look', theme),
                       _chip('Work outfit', theme),
                     ],
                   ),
                 ),
                 const SizedBox(height: 10),
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                   decoration: BoxDecoration(
                     color: theme.card,
                     border: Border.all(color: theme.cardBorder),
                     borderRadius: BorderRadius.circular(18),
                   ),
                   child: Row(
                     children: [
                       Icon(Icons.edit_note, color: theme.mutedText, size: 20),
                       const SizedBox(width: 8),
                       Expanded(
                         child: TextField(
                           controller: _textCtrl,
                           decoration: InputDecoration(border: InputBorder.none, hintText: 'Ask about your outfit...', hintStyle: TextStyle(color: theme.mutedText), isDense: true),
                           style: TextStyle(fontSize: 14, color: theme.textPrimary),
                           onSubmitted: (_) => _sendMsg(),
                         ),
                       ),
                       GestureDetector(
                         onTap: () => setState(() => _isListening = !_isListening),
                         child: Container(
                           width: 32, height: 32, margin: const EdgeInsets.only(right: 6),
                           decoration: BoxDecoration(color: _isListening ? theme.accent.primary : theme.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: theme.cardBorder)),
                           child: Icon(Icons.mic, size: 16, color: _isListening ? Colors.white : theme.accent.secondary),
                         ),
                       ),
                       GestureDetector(
                         onTap: _sendMsg,
                         child: Container(
                           width: 32, height: 32,
                           decoration: BoxDecoration(gradient: LinearGradient(colors: [theme.accent.secondary, theme.accent.tertiary]), borderRadius: BorderRadius.circular(10)),
                           child: const Icon(Icons.send, size: 14, color: Colors.white),
                         ),
                       )
                     ],
                   ),
                 )
              ],
            ),
          )
        ],
      ),
    ));
  }

  Widget _chip(String txt, dynamic theme) {
    return GestureDetector(
      onTap: () => _textCtrl.text = txt,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(color: theme.card, border: Border.all(color: theme.cardBorder), borderRadius: BorderRadius.circular(20)),
        child: Text(txt, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textPrimary)),
      ),
    );
  }
}
