/// API响应基础模型
class ApiResponse<T> {
  final int code;
  final T? data;
  final String message;
  final bool isSuccess;

  ApiResponse({
    required this.code,
    this.data,
    required this.message,
  }) : isSuccess = code == 0;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse<T>(
      code: json['code'] as int? ?? -1,
      data: fromJsonT != null && json['data'] != null
          ? fromJsonT(json['data'])
          : null,
      message: json['message'] as String? ?? '',
    );
  }

  factory ApiResponse.empty() => ApiResponse(code: -1, message: '网络异常');
}

/// API错误
class ApiException implements Exception {
  final int code;
  final String message;

  ApiException({required this.code, required this.message});

  @override
  String toString() => 'ApiException(code: $code, message: $message)';
}

/// 分页数据
class Pagination {
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;

  Pagination({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
      total: json['total'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
    );
  }
}

/// 分页响应
class PaginatedData<T> {
  final List<T> list;
  final Pagination pagination;

  PaginatedData({required this.list, required this.pagination});
}
