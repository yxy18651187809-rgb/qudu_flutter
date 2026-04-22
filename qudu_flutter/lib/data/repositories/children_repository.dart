import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../models/child_model.dart';

/// 儿童档案 Repository
/// 对接API契约第三章：CRUD
class ChildrenRepository {
  final ApiClient _apiClient;

  ChildrenRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// 获取儿童列表
  /// GET /api/v1/children
  Future<List<ChildModel>> getChildren() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/children',
    );
    if (!response.isSuccess || response.data == null) {
      throw ApiException(code: response.code, message: response.message);
    }
    final list = response.data!['list'] as List<dynamic>? ?? [];
    return list.map((e) => ChildModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 创建儿童档案
  /// POST /api/v1/children
  Future<ChildModel> createChild(ChildModel child) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/children',
      data: child.toCreateJson(),
    );
    if (!response.isSuccess || response.data == null) {
      throw ApiException(code: response.code, message: response.message);
    }
    return ChildModel.fromJson(response.data!);
  }

  /// 获取儿童详情
  /// GET /api/v1/children/:id
  Future<ChildModel> getChildDetail(String id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/children/$id',
    );
    if (!response.isSuccess || response.data == null) {
      throw ApiException(code: response.code, message: response.message);
    }
    return ChildModel.fromJson(response.data!);
  }

  /// 更新儿童档案
  /// PUT /api/v1/children/:id
  Future<ChildModel> updateChild(ChildModel child) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      '/children/${child.id}',
      data: child.toUpdateJson(),
    );
    if (!response.isSuccess || response.data == null) {
      throw ApiException(code: response.code, message: response.message);
    }
    return ChildModel.fromJson(response.data!);
  }

  /// 删除儿童档案（软删除）
  /// DELETE /api/v1/children/:id
  Future<void> deleteChild(String id) async {
    final response = await _apiClient.delete<Map<String, dynamic>>(
      '/children/$id',
    );
    if (!response.isSuccess) {
      throw ApiException(code: response.code, message: response.message);
    }
  }
}
