import '../../models/task_model.dart';
import '../task_datasource.dart';
import '../../../../../shared/infrastructure/mongodb/mongodb_service.dart';

/// MongoDB implementation of TaskDataSource
class TaskDataSourceMongoDB implements TaskDataSource {
  final MongoDBService mongoService;
  static const String collectionName = 'tasks';

  TaskDataSourceMongoDB(this.mongoService);

  MongoCollection get _collection => mongoService.collection(collectionName);

  @override
  Future<List<TaskModel>> getTasks() async {
    final docs = await _collection.find();
    return docs.map((doc) => TaskModel.fromJson(doc)).toList();
  }

  @override
  Future<List<TaskModel>> getTasksByProject(String projectId) async {
    final docs = await _collection.find({'projectId': projectId});
    return docs.map((doc) => TaskModel.fromJson(doc)).toList();
  }

  @override
  Future<List<TaskModel>> getTasksByStatus(String status) async {
    final docs = await _collection.find({'status': status});
    return docs.map((doc) => TaskModel.fromJson(doc)).toList();
  }

  @override
  Future<TaskModel?> getTaskById(String id) async {
    final doc = await _collection.findOne({'_id': id});
    return doc != null ? TaskModel.fromJson(doc) : null;
  }

  @override
  Future<TaskModel> createTask(TaskModel task) async {
    final doc = task.toJson();
    await _collection.insertOne(doc);
    return task;
  }

  @override
  Future<TaskModel> updateTask(TaskModel task) async {
    final doc = task.toJson();
    final success = await _collection.updateOne(
      {'_id': task.id},
      doc,
    );

    if (!success) {
      throw Exception('Task not found: ${task.id}');
    }

    return task;
  }

  @override
  Future<void> deleteTask(String id) async {
    final success = await _collection.deleteOne({'_id': id});

    if (!success) {
      throw Exception('Task not found: $id');
    }
  }

  @override
  Future<List<TaskModel>> searchTasks(String query) async {
    final allDocs = await _collection.find();

    // Simple text search in title and description
    final results = allDocs.where((doc) {
      final title = (doc['title'] as String? ?? '').toLowerCase();
      final description = (doc['description'] as String? ?? '').toLowerCase();
      final searchQuery = query.toLowerCase();

      return title.contains(searchQuery) || description.contains(searchQuery);
    }).toList();

    return results.map((doc) => TaskModel.fromJson(doc)).toList();
  }

  @override
  Future<List<TaskModel>> getTasksFiltered(Map<String, dynamic> filters) async {
    final allDocs = await _collection.find();

    // Filter based on provided criteria
    final results = allDocs.where((doc) {
      bool matches = true;

      // Filter by status
      if (filters['status'] != null && doc['status'] != filters['status']) {
        matches = false;
      }

      // Filter by priority
      if (filters['priority'] != null &&
          doc['priority'] != filters['priority']) {
        matches = false;
      }

      // Filter by projectId
      if (filters['projectId'] != null &&
          doc['projectId'] != filters['projectId']) {
        matches = false;
      }

      // Filter by tags
      if (filters['tags'] != null) {
        final requiredTags = filters['tags'] as List<String>;
        final docTags = (doc['tags'] as List<dynamic>?)?.cast<String>() ?? [];

        if (!requiredTags.every((tag) => docTags.contains(tag))) {
          matches = false;
        }
      }

      return matches;
    }).toList();

    return results.map((doc) => TaskModel.fromJson(doc)).toList();
  }
}
