import 'package:flutter/material.dart';
import 'database.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyTasks());
}

class MyTasks extends StatelessWidget {
  const MyTasks({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyTasks',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6200EE),
          primary: const Color(0xFF6200EE),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF6200EE),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return const Color(0xFF6200EE);
            return Colors.transparent;
          }),
          checkColor: WidgetStateProperty.all(Colors.white),
          side: const BorderSide(color: Color(0xFFE0E0E0), width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        useMaterial3: true,
      ),
      home: const TaskListScreen(),
    );
  }
}

enum FilterType { all, active, completed }

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final TextEditingController _textController = TextEditingController();
  List<Task> _tasks = [];
  bool _isLoading = true;
  FilterType _filter = FilterType.all;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    final tasks = await _db.getAllTasks();
    setState(() {
      _tasks = tasks;
      _isLoading = false;
    });
  }

  List<Task> get _filteredTasks {
    switch (_filter) {
      case FilterType.active:
        return _tasks.where((t) => !t.completed).toList();
      case FilterType.completed:
        return _tasks.where((t) => t.completed).toList();
      case FilterType.all:
        return _tasks;
    }
  }

  int get _totalCount => _tasks.length;
  int get _activeCount => _tasks.where((t) => !t.completed).toList().length;
  int get _completedCount => _tasks.where((t) => t.completed).toList().length;

  Future<void> _addTask() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    final task = Task(
      text: text,
      completed: false,
      position: _tasks.length,
    );
    await _db.insertTask(task);
    _textController.clear();
    await _loadTasks();
  }

  Future<void> _toggleTask(Task task) async {
    task.completed = !task.completed;
    await _db.updateTask(task);
    await _loadTasks();
  }

  Future<void> _deleteTask(Task task) async {
    await _db.deleteTask(task.id!);
    await _loadTasks();
  }

  Future<void> _editTask(Task task) async {
    final controller = TextEditingController(text: task.text);
    final newText = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Task',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF212121))),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter a task...',
            hintStyle: TextStyle(color: Color(0xFFBDBDBD)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: Color(0xFF6200EE), width: 2),
            ),
          ),
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF757575), fontSize: 15)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save',
                style: TextStyle(color: Color(0xFF6200EE), fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newText != null && newText.isNotEmpty && newText != task.text) {
      task.text = newText;
      await _db.updateTask(task);
      await _loadTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              color: const Color(0xFF6200EE),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'My Tasks',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFFFFFF),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_activeCount task${_activeCount != 1 ? 's' : ''} left to do',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFFB39DDB),
                    ),
                  ),
                ],
              ),
            ),

            // Stats Cards
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  _buildStatCard('Total', _totalCount),
                  const SizedBox(width: 12),
                  _buildStatCard('Active', _activeCount),
                  const SizedBox(width: 12),
                  _buildStatCard('Completed', _completedCount),
                ],
              ),
            ),

            // Input Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: TextField(
                          controller: _textController,
                          decoration: const InputDecoration(
                            hintText: 'Add a new task...',
                            hintStyle: TextStyle(color: Color(0xFFBDBDBD), fontSize: 16),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          onSubmitted: (_) => _addTask(),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Material(
                        color: const Color(0xFF6200EE),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _addTask,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            child: Text(
                              'Add',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Filter Tabs
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  _buildFilterTab('All', FilterType.all),
                  const SizedBox(width: 8),
                  _buildFilterTab('Active', FilterType.active),
                  const SizedBox(width: 8),
                  _buildFilterTab('Completed', FilterType.completed),
                ],
              ),
            ),

            // Task List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF6200EE)))
                  : _filteredTasks.isEmpty
                      ? Center(
                          child: Text(
                            _filter == FilterType.all
                                ? 'No tasks yet.\nAdd one above!'
                                : _filter == FilterType.active
                                    ? 'No active tasks.'
                                    : 'No completed tasks.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 15),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: _filteredTasks.length,
                          itemBuilder: (context, index) {
                            final task = _filteredTasks[index];
                            return _buildTaskCard(task);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, int count) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6200EE),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Color(0xFF757575),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String label, FilterType filter) {
    final isActive = _filter == filter;
    return Material(
      color: isActive ? const Color(0xFF6200EE) : Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _filter = filter),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : const Color(0xFF757575),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Checkbox(
            value: task.completed,
            onChanged: (_) => _toggleTask(task),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => _editTask(task),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF212121),
                      decoration: task.completed ? TextDecoration.lineThrough : null,
                      decorationColor: const Color(0xFF9E9E9E),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task.createdAt,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _editTask(task),
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.edit_outlined, size: 20, color: Color(0xFF757575)),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => _deleteTask(task),
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.delete_outline, size: 20, color: Color(0xFF757575)),
            ),
          ),
        ],
      ),
    );
  }
}