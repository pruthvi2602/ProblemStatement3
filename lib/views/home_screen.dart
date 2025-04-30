// views/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/providers.dart';
import '../models/task.dart';
import 'task_list.dart';
import 'voice_command_button.dart';
import 'connectivity_status.dart';
import 'voice_feedback_banner.dart';

class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider);
    final isProcessing = ref.watch(processingCommandProvider);
    final feedbackMessage = ref.watch(feedbackMessageProvider);
    final isListening = ref.watch(listeningStateProvider);

    // Add some sample tasks if the list is empty
    if (tasks.isEmpty) {
      final sampleTasks = [
        Task(
          title: 'Buy groceries',
          description: 'Milk, eggs, bread, and fruits',
          dueDate: DateTime.now().add(Duration(days: 1)),
          priority: 2, // medium priority
          isCompleted: false,
        ),
        Task(
          title: 'Finish project report',
          description: 'Complete the quarterly analysis',
          dueDate: DateTime.now().add(Duration(days: 3)),
          priority: 1, // high priority
          isCompleted: false,
        ),
        Task(
          title: 'Call mom',
          description: 'Check in and plan weekend visit',
          dueDate: DateTime.now().add(Duration(days: 2)),
          priority: 3, // low priority
          isCompleted: false,
        ),
        Task(
          title: 'Schedule dentist appointment',
          description: 'Call Dr. Smith for checkup',
          dueDate: DateTime.now().add(Duration(days: 5)),
          priority: 2,
          isCompleted: false,
        ),
        Task(
          title: 'Pay electricity bill',
          description: 'Due by end of month',
          dueDate: DateTime.now().add(Duration(days: 7)),
          priority: 1,
          isCompleted: false,
        ),
      ];

      // Add each task individually
      Future.microtask(() async {
        for (final task in sampleTasks) {
          await ref.read(tasksProvider.notifier).addTask(task);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('TaskFlow'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            tooltip: 'Add Task Manually',
            onPressed: () => _showAddTaskDialog(context, ref),
          ),
          IconButton(
            icon: Icon(Icons.info_outline),
            tooltip: 'Voice Command Help',
            onPressed: () => _showVoiceCommandHelp(context),
          ),
          ConnectivityStatusIndicator(),
        ],
      ),
      body: Column(
        children: [
          // Feedback banner for voice commands
          if (feedbackMessage != null)
            VoiceFeedbackBanner(message: feedbackMessage),

          // Task list - main content
          Expanded(
            child: tasks.isEmpty
                ? Center(
                    child:
                        Text('No tasks yet. Try adding one with your voice!'))
                : TaskList(tasks: tasks),
          ),
        ],
      ),
      floatingActionButton: VoiceCommandButton(
        isListening: isListening,
        isProcessing: isProcessing,
      ),
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildInfoButton(context),
            SizedBox(width: 48), // Space for the FAB
            _buildFilterButton(context),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildInfoButton(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.info_outline),
      tooltip: 'Voice Command Help',
      onPressed: () {
        _showVoiceCommandHelp(context);
      },
    );
  }

  Widget _buildFilterButton(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.filter_list),
      tooltip: 'Filter Tasks',
      onPressed: () {
        // Show filter options
      },
    );
  }

  void _showVoiceCommandHelp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Voice Command Examples',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 16),
              _buildHelpItem(context, 'Add a task', 'Add buy groceries'),
              _buildHelpItem(
                  context, 'Add with due date', 'Add call mom due tomorrow'),
              _buildHelpItem(context, 'Add with priority',
                  'Add finish report priority high'),
              _buildHelpItem(
                  context, 'Complete a task', 'Complete buy groceries'),
              _buildHelpItem(context, 'Delete a task', 'Delete call mom'),
              _buildHelpItem(context, 'List all tasks', 'Show my tasks'),
              _buildHelpItem(context, 'Search tasks', 'Find groceries'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHelpItem(BuildContext context, String title, String example) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          Text('Example: "$example"',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime? selectedDate;
    int? selectedPriority;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Task Title',
                    hintText: 'Enter task title',
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter task description',
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                ListTile(
                  title: Text('Due Date'),
                  trailing: TextButton(
                    child: Text(selectedDate == null
                        ? 'Select Date'
                        : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(Duration(days: 365)),
                      );
                      if (date != null) {
                        selectedDate = date;
                      }
                    },
                  ),
                ),
                ListTile(
                  title: Text('Priority'),
                  trailing: DropdownButton<int>(
                    value: selectedPriority ?? 2,
                    items: [
                      DropdownMenuItem(value: 1, child: Text('High')),
                      DropdownMenuItem(value: 2, child: Text('Medium')),
                      DropdownMenuItem(value: 3, child: Text('Low')),
                    ],
                    onChanged: (value) {
                      selectedPriority = value;
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  final newTask = Task(
                    title: titleController.text,
                    description: descriptionController.text,
                    dueDate: selectedDate,
                    priority: selectedPriority ?? 2,
                    isCompleted: false,
                  );
                  ref.read(tasksProvider.notifier).addTask(newTask);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}
