import 'package:keep_track/shared/infrastructure/supabase/supabase_service.dart';

import '../../../domain/entities/bucket.dart';
import '../bucket_datasource.dart';
import '../../models/bucket_model.dart';

/// Supabase implementation of bucket data source
class BucketDataSourceSupabase implements BucketDataSource {
  final SupabaseService supabaseService;
  static const String tableName = 'buckets';

  BucketDataSourceSupabase(this.supabaseService);

  @override
  Future<List<Bucket>> getBuckets() async {
    final response = await supabaseService.client
        .from(tableName)
        .select()
        .eq('user_id', supabaseService.userId!)
        .eq('is_archive', false)
        .order('created_at', ascending: false);

    return (response as List)
        .map((doc) => BucketModel.fromJson(doc as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Bucket?> getBucketById(String id) async {
    final response = await supabaseService.client
        .from(tableName)
        .select()
        .eq('id', id)
        .eq('user_id', supabaseService.userId!)
        .maybeSingle();

    return response != null
        ? BucketModel.fromJson(response as Map<String, dynamic>)
        : null;
  }

  @override
  Future<List<Bucket>> getByIds(List<String> ids) async {
    final response = await supabaseService.client
        .from(tableName)
        .select()
        .filter('id', 'in', ids)
        .eq('user_id', supabaseService.userId!)
        .order('created_at', ascending: false);

    return (response as List)
        .map((doc) => BucketModel.fromJson(doc as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Bucket> createBucket(BucketModel bucket) async {
    final doc = bucket.toJson();
    final response = await supabaseService.client
        .from(tableName)
        .insert(doc)
        .select()
        .single();

    return BucketModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<Bucket> updateBucket(BucketModel bucket) async {
    if (bucket.id == null) {
      throw Exception('Cannot update bucket without an ID');
    }

    final doc = bucket.toJson();
    final response = await supabaseService.client
        .from(tableName)
        .update(doc)
        .eq('id', bucket.id!)
        .eq('user_id', supabaseService.userId!)
        .select()
        .single();

    return BucketModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<void> deleteBucket(String id) async {
    await supabaseService.client
        .from(tableName)
        .delete()
        .eq('id', id)
        .eq('user_id', supabaseService.userId!);
  }
}