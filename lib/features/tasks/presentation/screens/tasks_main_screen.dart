import 'package:flutter/material.dart';
import 'package:keep_track/core/ui/app_layout_controller.dart';
import 'package:keep_track/core/ui/ui.dart';
import 'tabs/tasks_tab.dart';
import 'tabs/projects_tab.dart';
import 'tabs/pomodoro_tab.dart';

/// Main Tasks Screen with Inner Tabs
class TasksMainScreen extends ScopedScreen {
  const TasksMainScreen({super.key});

  @override
  State<TasksMainScreen> createState() => _TasksMainScreenState();
}

class _TasksMainScreenState extends ScopedScreenState<TasksMainScreen>
    with AppLayoutControlled, SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void registerServices() {
    // Services will be wired later
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void onReady() {
    configureLayout(title: 'Tasks', showBottomNav: true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Inner Tab Bar
        Container(
          color: Theme.of(context).colorScheme.surface,
          child: TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor:
                Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabs: const [
              Tab(
                icon: Icon(Icons.task_alt),
                text: 'Tasks',
              ),
              Tab(
                icon: Icon(Icons.folder),
                text: 'Projects',
              ),
              Tab(
                icon: Icon(Icons.timer),
                text: 'Pomodoro',
              ),
            ],
          ),
        ),
        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              TasksTab(),
              ProjectsTab(),
              PomodoroTab(),
            ],
          ),
        ),
      ],
    );
  }
}
