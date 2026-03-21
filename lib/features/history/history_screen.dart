import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/database/hive_service.dart';
import '../../core/models/training_session.dart';
import '../../shared/theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _db = HiveService.instance;
  DateTime _focusedDay = DateTime.now();

  Set<DateTime> get _completedDays => _db.getCompletedDaysThisMonth();
  int get _streakDays => _db.getStreakDays();
  int get _totalSeconds => _db.getTotalDurationSeconds();

  String get _totalTimeLabel {
    final minutes = _totalSeconds ~/ 60;
    if (minutes < 60) return '$minutes分';
    return '${minutes ~/ 60}時間${minutes % 60}分';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('トレーニング履歴')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatsRow(streakDays: _streakDays, totalTimeLabel: _totalTimeLabel),
              const SizedBox(height: 24),
              Text('月間カレンダー', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              _CalendarCard(
                focusedDay: _focusedDay,
                completedDays: _completedDays,
                onPageChanged: (day) => setState(() => _focusedDay = day),
              ),
              const SizedBox(height: 24),
              Text('最近のトレーニング', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              _RecentSessionsList(db: _db),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int streakDays;
  final String totalTimeLabel;
  const _StatsRow({required this.streakDays, required this.totalTimeLabel});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(label: '連続達成', value: '$streakDays日', icon: Icons.local_fire_department)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(label: '累計時間', value: totalTimeLabel, icon: Icons.timer)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 28, color: AppTheme.primary),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppTheme.primary)),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  final DateTime focusedDay;
  final Set<DateTime> completedDays;
  final ValueChanged<DateTime> onPageChanged;
  const _CalendarCard({
    required this.focusedDay,
    required this.completedDays,
    required this.onPageChanged,
  });

  bool _isCompleted(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return completedDays.contains(d);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: TableCalendar(
        locale: 'ja_JP',
        firstDay: DateTime(2024, 1, 1),
        lastDay: DateTime(2030, 12, 31),
        focusedDay: focusedDay,
        onPageChanged: onPageChanged,
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
          ),
          defaultTextStyle: const TextStyle(fontSize: 15),
          weekendTextStyle: const TextStyle(fontSize: 15, color: Colors.red),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        calendarBuilders: CalendarBuilders(
          dowBuilder: (context, day) {
            const labels = ['月', '火', '水', '木', '金', '土', '日'];
            final label = labels[day.weekday - 1];
            final isWeekend = day.weekday == DateTime.saturday ||
                day.weekday == DateTime.sunday;
            return Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: isWeekend ? Colors.red : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },
          defaultBuilder: (context, day, focusedDay) {
            if (_isCompleted(day)) {
              return Container(
                margin: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('${day.day}', style: const TextStyle(color: Colors.white, fontSize: 15)),
                ),
              );
            }
            return null;
          },
        ),
      ),
    );
  }
}

class _RecentSessionsList extends StatelessWidget {
  final HiveService db;
  const _RecentSessionsList({required this.db});

  @override
  Widget build(BuildContext context) {
    final sessions = db.getAllSessions().take(10).toList();
    if (sessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('まだトレーニング記録がありません', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
        ),
      );
    }
    return Column(
      children: sessions.map((s) {
        final date = s.date;
        final label = '${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
        return ListTile(
          leading: Icon(s.type.icon, size: 24, color: AppTheme.primary),
          title: Text(s.type.displayName, style: Theme.of(context).textTheme.bodyLarge),
          subtitle: Text(label, style: Theme.of(context).textTheme.bodySmall),
          trailing: const Icon(Icons.check_circle_rounded, color: AppTheme.primary),
        );
      }).toList(),
    );
  }
}
