import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/notification_service.dart';
import '../state/app_state.dart';
import '../theme/palette.dart';
import '../widgets/common.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: const <Widget>[
          TabBar(
            tabs: <Widget>[
              Tab(text: 'Jadwal Irigasi'),
              Tab(text: 'Perawatan Tanaman'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: <Widget>[
                _IrrigationTab(),
                _TasksTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IrrigationTab extends StatelessWidget {
  const _IrrigationTab();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final schedules = state.schedules;
    final theme = Theme.of(context);

    return Stack(
      children: <Widget>[
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: <Widget>[
            if (schedules.isEmpty)
              const AppCard(
                child: EmptyState(
                  icon: Icons.event_busy,
                  title: 'Belum ada jadwal',
                  message: 'Tambahkan jadwal penyiraman dengan tombol +.',
                ),
              )
            else
              ...schedules.map(
                (s) => Dismissible(
                  key: ValueKey<String>(s.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Palette.danger,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => state.removeSchedule(s.id),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppCard(
                      child: Row(
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: s.enabled
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              children: <Widget>[
                                Text(
                                  s.timeLabel,
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                                ),
                                Text('WIB', style: theme.textTheme.labelSmall),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(s.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Text(
                                  '${s.dayLabel} • ${s.durationMinutes} menit',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(value: s.enabled, onChanged: (_) => state.toggleSchedule(s.id)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: 'add-schedule',
            onPressed: () => _showAddSchedule(context),
            icon: const Icon(Icons.add_alarm),
            label: const Text('Jadwal baru'),
          ),
        ),
      ],
    );
  }

  void _showAddSchedule(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _AddScheduleSheet(),
    );
  }
}

class _AddScheduleSheet extends StatefulWidget {
  const _AddScheduleSheet();

  @override
  State<_AddScheduleSheet> createState() => _AddScheduleSheetState();
}

class _AddScheduleSheetState extends State<_AddScheduleSheet> {
  final _label = TextEditingController(text: 'Penyiraman');
  TimeOfDay _time = const TimeOfDay(hour: 6, minute: 0);
  double _duration = 10;
  final Set<int> _days = <int>{};

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final theme = Theme.of(context);
    const dayNames = <int, String>{1: 'Sen', 2: 'Sel', 3: 'Rab', 4: 'Kam', 5: 'Jum', 6: 'Sab', 7: 'Min'};

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Jadwal Penyiraman Baru', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _label,
            decoration: const InputDecoration(labelText: 'Nama jadwal', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showTimePicker(context: context, initialTime: _time);
                    if (picked != null) setState(() => _time = picked);
                  },
                  icon: const Icon(Icons.access_time),
                  label: Text('Pukul ${_time.format(context)}'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Durasi: ${_duration.round()} menit', style: theme.textTheme.bodyMedium),
          ),
          Slider(
            value: _duration,
            min: 2,
            max: 30,
            divisions: 28,
            onChanged: (v) => setState(() => _duration = v),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Hari (kosong = setiap hari)', style: theme.textTheme.bodyMedium),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: dayNames.entries.map((e) {
              final selected = _days.contains(e.key);
              return FilterChip(
                label: Text(e.value),
                selected: selected,
                onSelected: (v) => setState(() {
                  if (v) {
                    _days.add(e.key);
                  } else {
                    _days.remove(e.key);
                  }
                }),
              );
            }).toList(),
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: () {
              state.addSchedule(
                IrrigationSchedule(
                  id: 'sch-${DateTime.now().microsecondsSinceEpoch}',
                  farmId: state.selectedFarm.id,
                  label: _label.text.trim().isEmpty ? 'Penyiraman' : _label.text.trim(),
                  hour: _time.hour,
                  minute: _time.minute,
                  durationMinutes: _duration.round(),
                  enabled: true,
                  weekdays: Set<int>.from(_days),
                ),
              );
              Navigator.of(context).pop();
              NotificationService.toast('Jadwal ditambahkan');
            },
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            child: const Text('Simpan Jadwal'),
          ),
        ],
      ),
    );
  }
}

class _TasksTab extends StatelessWidget {
  const _TasksTab();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final tasks = state.tasks;

    return Stack(
      children: <Widget>[
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: <Widget>[
            if (tasks.isEmpty)
              const AppCard(
                child: EmptyState(
                  icon: Icons.task_alt,
                  title: 'Belum ada tugas',
                  message: 'Tambahkan tugas perawatan tanaman dengan tombol +.',
                ),
              )
            else
              ...tasks.map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Checkbox(value: t.done, onChanged: (_) => state.toggleTask(t.id)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                t.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  decoration: t.done ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              if (t.notes.isNotEmpty) ...<Widget>[
                                const SizedBox(height: 3),
                                Text(
                                  t.notes,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Row(
                                children: <Widget>[
                                  Chip(
                                    visualDensity: VisualDensity.compact,
                                    avatar: Icon(t.type.icon, size: 14),
                                    label: Text(t.type.label),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.event,
                                    size: 14,
                                    color: t.isOverdue
                                        ? Palette.danger
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    kDateTimeFormat.format(t.due),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: t.isOverdue
                                          ? Palette.danger
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Hapus',
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () => state.removeTask(t.id),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: 'add-task',
            onPressed: () => _showAddTask(context),
            icon: const Icon(Icons.add_task),
            label: const Text('Tugas baru'),
          ),
        ),
      ],
    );
  }

  void _showAddTask(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _AddTaskSheet(),
    );
  }
}

class _AddTaskSheet extends StatefulWidget {
  const _AddTaskSheet();

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _title = TextEditingController();
  final _notes = TextEditingController();
  TaskType _type = TaskType.other;
  DateTime _due = DateTime.now().add(const Duration(days: 1));

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('Tugas Perawatan Baru', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Judul tugas', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Catatan (opsional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<TaskType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Jenis', border: OutlineInputBorder()),
              items: TaskType.values
                  .map((t) => DropdownMenuItem<TaskType>(value: t, child: Text(t.label)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? TaskType.other),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _due,
                  firstDate: DateTime.now().subtract(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date == null || !context.mounted) return;
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(_due),
                );
                setState(() {
                  _due = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time?.hour ?? _due.hour,
                    time?.minute ?? _due.minute,
                  );
                });
              },
              icon: const Icon(Icons.event),
              label: Text('Tenggat: ${kDateTimeFormat.format(_due)}'),
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: () {
                if (_title.text.trim().isEmpty) {
                  NotificationService.toast('Judul tugas belum diisi', error: true);
                  return;
                }
                state.addTask(
                  PlantTask(
                    id: 'task-${DateTime.now().microsecondsSinceEpoch}',
                    farmId: state.selectedFarm.id,
                    title: _title.text.trim(),
                    notes: _notes.text.trim(),
                    type: _type,
                    due: _due,
                  ),
                );
                Navigator.of(context).pop();
                NotificationService.toast('Tugas ditambahkan');
              },
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Simpan Tugas'),
            ),
          ],
        ),
      ),
    );
  }
}

