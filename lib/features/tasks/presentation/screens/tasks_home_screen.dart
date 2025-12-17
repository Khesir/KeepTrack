import 'package:flutter/material.dart';
import 'package:persona_codex/core/ui/app_layout_controller.dart';
import 'package:persona_codex/core/ui/ui.dart';
import 'task_list_screen.dart';
import 'package:persona_codex/features/projects/presentation/screens/project_list_screen.dart';
import 'tabs/logs_tab.dart';

class TasksHomeScreen extends ScopedScreen {
  const TasksHomeScreen({super.key});

  @override
  State<TasksHomeScreen> createState() => _TasksHomeScreenState();
}

class _TasksHomeScreenState extends ScopedScreenState<TasksHomeScreen>
    with AppLayoutControlled {
  int _topIndex = 0;

  @override
  void registerServices() {
    // No services to register - using global controllers
  }

  @override
  void onReady() {
    configureLayout(title: 'Tasks', showBottomNav: true);
  }

  final List<String> topTabs = ['Tasks', 'Projects', 'Time & Planning', 'Sessions', 'Logs'];

  void _onTabSelected(int index) {
    setState(() {
      _topIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Inner top tabs
        Container(
          color: Colors.green[50],
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(topTabs.length, (index) {
              final isActive = _topIndex == index;
              return GestureDetector(
                onTap: () => _onTabSelected(index),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      topTabs[index],
                      style: TextStyle(
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isActive ? Colors.green : Colors.grey[700],
                        fontSize: 13,
                      ),
                    ),
                    if (isActive)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        height: 3,
                        width: 40,
                        color: Colors.green,
                      ),
                  ],
                ),
              );
            }),
          ),
        ),

        // Inner tab content
        Expanded(
          child: IndexedStack(
            index: _topIndex,
            children: [
              // Tasks Tab
              const TaskListScreen(),

              // Projects Tab
              const ProjectListScreen(),

              // Time & Planning Tab - TODO: Future Google Calendar integration
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Time & Planning',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Coming soon - Google Calendar integration',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              // Sessions Tab - TODO: Session tracking
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Sessions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Coming soon - track work sessions and time',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              // Logs Tab
              const TaskLogsTab(),
            ],
          ),
        ),
      ],
    );
  }
}
