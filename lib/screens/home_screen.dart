import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../db/database_helper.dart';
import '../utils/notification_helper.dart';
import '../providers/theme_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Task> tasks = [];
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final data = await DatabaseHelper.instance.getTasks();
    setState(() {
      tasks = data;
    });
  }

  Future<void> _showTaskDialog({Task? task}) async {
    final titleController = TextEditingController(text: task?.title ?? '');
    final descController = TextEditingController(text: task?.description ?? '');
    DateTime? selectedDate = task?.deadline;

    final isEdit = task != null;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? 'Edit Task' : 'New Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    selectedDate != null
                        ? 'Deadline: ${selectedDate?.toLocal().toString().split(' ')[0]}'
                        : 'Choose Deadline',
                  ),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final desc = descController.text.trim();
                if (title.isEmpty) return;

                if (isEdit) {
                  await DatabaseHelper.instance.updateTask(
                    Task(
                      id: task.id,
                      title: title,
                      description: desc,
                      isDone: task.isDone,
                      deadline: selectedDate,
                    ),
                  );
                } else {
                  await DatabaseHelper.instance.insertTask(
                    Task(
                      title: title,
                      description: desc,
                      deadline: selectedDate,
                    ),
                  );

                  if (selectedDate != null) {
                    final notifDate = selectedDate?.subtract(
                      const Duration(days: 1),
                    );
                    if (notifDate != null &&
                        notifDate.isAfter(DateTime.now())) {
                      await NotificationHelper.scheduleNotification(
                        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                        title: 'Upcoming Task',
                        body: '$title is due tomorrow!',
                        scheduledDate: notifDate,
                      );
                    }
                  }
                }

                if (!context.mounted) return;
                Navigator.pop(context);
                _loadTasks();
              },
              child: Text(isEdit ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteTask(int id) async {
    await DatabaseHelper.instance.deleteTask(id);
    _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = tasks.where((task) {
      if (_filter == 'All') return true;
      if (_filter == 'Completed') return task.isDone;
      if (_filter == 'Incomplete') return !task.isDone;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('TidyTask'),
        centerTitle: true,
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _filter,
              icon: const Icon(Icons.filter_list, color: Colors.white),
              dropdownColor: Colors.teal,
              items: ['All', 'Completed', 'Incomplete']
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(
                        value,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _filter = value!;
                });
              },
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              final themeProvider = Provider.of<ThemeProvider>(
                context,
                listen: false,
              );
              if (value == 'Light') {
                themeProvider.setTheme(ThemeMode.light);
              } else if (value == 'Dark') {
                themeProvider.setTheme(ThemeMode.dark);
              } else {
                themeProvider.setTheme(ThemeMode.system);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Light', child: Text('Light Mode')),
              const PopupMenuItem(value: 'Dark', child: Text('Dark Mode')),
              const PopupMenuItem(
                value: 'System',
                child: Text('System Default'),
              ),
            ],
          ),
        ],
      ),
      body: filteredTasks.isEmpty
          ? const Center(child: Text('No tasks found'))
          : ListView.builder(
              itemCount: filteredTasks.length,
              itemBuilder: (_, index) {
                final task = filteredTasks[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  elevation: 2,
                  child: ListTile(
                    leading: Checkbox(
                      value: task.isDone,
                      onChanged: (_) async {
                        await DatabaseHelper.instance.toggleTaskStatus(task);
                        _loadTasks();
                      },
                    ),
                    title: Text(
                      task.title,
                      style: TextStyle(
                        decoration: task.isDone
                            ? TextDecoration.lineThrough
                            : null,
                        color: task.isDone ? Colors.grey : null,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (task.description != null &&
                            task.description!.isNotEmpty)
                          Text(
                            task.description!,
                            style: TextStyle(
                              decoration: task.isDone
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: task.isDone ? Colors.grey : null,
                            ),
                          ),
                        if (task.deadline != null)
                          Text(
                            'Deadline: ${task.deadline!.toLocal().toString().split(' ')[0]}',
                            style: TextStyle(
                              color: task.isDone
                                  ? Colors.grey
                                  : Colors.redAccent,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showTaskDialog(task: task),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteTask(task.id!),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
