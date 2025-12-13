import '../../models/project_model.dart';
import '../project_datasource.dart';
import 'mongodb_service.dart';

/// MongoDB implementation of ProjectDataSource
class ProjectDataSourceMongoDB implements ProjectDataSource {
  final MongoDBService mongoService;
  static const String collectionName = 'projects';

  ProjectDataSourceMongoDB(this.mongoService);

  MongoCollection get _collection => mongoService.collection(collectionName);

  @override
  Future<List<ProjectModel>> getProjects() async {
    final docs = await _collection.find();
    return docs.map((doc) => ProjectModel.fromJson(doc)).toList();
  }

  @override
  Future<List<ProjectModel>> getActiveProjects() async {
    final docs = await _collection.find({'isArchived': false});
    return docs.map((doc) => ProjectModel.fromJson(doc)).toList();
  }

  @override
  Future<ProjectModel?> getProjectById(String id) async {
    final doc = await _collection.findOne({'_id': id});
    return doc != null ? ProjectModel.fromJson(doc) : null;
  }

  @override
  Future<ProjectModel> createProject(ProjectModel project) async {
    final doc = project.toJson();
    await _collection.insertOne(doc);
    return project;
  }

  @override
  Future<ProjectModel> updateProject(ProjectModel project) async {
    final doc = project.toJson();
    final success = await _collection.updateOne(
      {'_id': project.id},
      doc,
    );

    if (!success) {
      throw Exception('Project not found: ${project.id}');
    }

    return project;
  }

  @override
  Future<void> deleteProject(String id) async {
    final success = await _collection.deleteOne({'_id': id});

    if (!success) {
      throw Exception('Project not found: $id');
    }
  }
}
