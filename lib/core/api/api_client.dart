import 'package:dio/dio.dart';

import '../auth/token_store.dart';
import '../constants.dart';

/// 后端 API 客户端：自动携带 Bearer 令牌，401 时自动刷新并重试一次
class ApiClient {
  ApiClient._() {
    dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
    ));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = TokenStore.instance.accessToken;
        if (token != null && !options.path.startsWith('/api/auth/')) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final status = error.response?.statusCode;
        final retried = error.requestOptions.extra['_retried'] == true;
        if (status == 401 && !retried && !_isAuthPath(error.requestOptions)) {
          final refreshed = await _refreshToken();
          if (refreshed) {
            try {
              final req = error.requestOptions;
              req.extra['_retried'] = true;
              req.headers['Authorization'] =
                  'Bearer ${TokenStore.instance.accessToken}';
              final resp = await dio.fetch(req);
              return handler.resolve(resp);
            } catch (e) {
              return handler.next(error);
            }
          }
        }
        handler.next(error);
      },
    ));
  }

  static final ApiClient instance = ApiClient._();
  late final Dio dio;

  bool _isAuthPath(RequestOptions o) => o.path.startsWith('/api/auth/');

  Future<bool>? _refreshing;

  /// 通过后端中转刷新令牌（国内无法直连 Supabase Auth）；并发请求共享同一次刷新
  Future<bool> _refreshToken() {
    final inFlight = _refreshing;
    if (inFlight != null) return inFlight;
    final future = _doRefresh().whenComplete(() => _refreshing = null);
    _refreshing = future;
    return future;
  }

  Future<bool> _doRefresh() async {
    final refresh = TokenStore.instance.refreshToken;
    if (refresh == null) return false;
    try {
      final raw = Dio(BaseOptions(baseUrl: AppConstants.apiBaseUrl));
      final resp = await raw.post('/api/auth/refresh',
          data: {'refresh_token': refresh});
      final data = resp.data;
      if (data is Map && data['ok'] == true) {
        await TokenStore.instance.save(
          access: data['access_token'] as String,
          refresh: data['refresh_token'] as String,
        );
        return true;
      }
    } on DioException catch (e) {
      // 仅当服务端明确拒绝 refresh_token 时才判定会话失效
      final status = e.response?.statusCode;
      if (status == 400 || status == 401) {
        await TokenStore.instance.clear();
      }
      return false;
    } catch (_) {
      return false;
    }
    // 服务端返回非 ok（refresh_token 已失效）：清空令牌由会话层跳回登录页
    await TokenStore.instance.clear();
    return false;
  }

  /// 从 DioException 提取后端返回的错误文案
  static String errorMessage(Object e, {String fallback = '网络异常，请稍后重试'}) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['error'] is String) {
        return data['error'] as String;
      }
    }
    return fallback;
  }
}
