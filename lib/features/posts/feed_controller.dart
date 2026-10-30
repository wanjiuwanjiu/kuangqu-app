import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/constants.dart';
import 'post_model.dart';

/// 当前选中的分类（'全部' 表示不筛选）
class FeedCategory extends Notifier<String> {
  @override
  String build() => '全部';

  void select(String value) => state = value;
}

final feedCategoryProvider =
    NotifierProvider<FeedCategory, String>(FeedCategory.new);

/// 帖子流状态
class FeedState {
  const FeedState({
    required this.posts,
    required this.liked,
    this.nextCursor,
    this.hasMore = false,
    this.loadingMore = false,
  });

  final List<Post> posts;
  final Set<String> liked;
  final String? nextCursor;
  final bool hasMore;
  final bool loadingMore;

  FeedState copyWith({
    List<Post>? posts,
    Set<String>? liked,
    String? nextCursor,
    bool? hasMore,
    bool? loadingMore,
  }) =>
      FeedState(
        posts: posts ?? this.posts,
        liked: liked ?? this.liked,
        nextCursor: nextCursor ?? this.nextCursor,
        hasMore: hasMore ?? this.hasMore,
        loadingMore: loadingMore ?? this.loadingMore,
      );
}

final feedProvider =
    AsyncNotifierProvider<FeedNotifier, FeedState>(FeedNotifier.new);

class FeedNotifier extends AsyncNotifier<FeedState> {
  static const _pageSize = 10;

  @override
  Future<FeedState> build() async {
    // 分类变化时自动重建：切分类立即回到首屏
    final category = ref.watch(feedCategoryProvider);
    final page = await _fetchPage(
      category == '全部' ? null : category,
      null,
    );
    return FeedState(
      posts: page.posts,
      liked: page.liked,
      nextCursor: page.nextCursor,
      hasMore: page.nextCursor != null,
    );
  }

  Future<_Page> _fetchPage(String? category, String? cursor) async {
    final params = <String, dynamic>{'limit': _pageSize};
    if (category != null) params['cat'] = category;
    if (cursor != null) params['cursor'] = cursor;

    final resp = await ApiClient.instance.dio.get(
      '/api/posts',
      queryParameters: params,
    );
    final data = resp.data as Map;
    final posts = (data['posts'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Post.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return _Page(
      posts: posts,
      liked: (data['liked'] as List? ?? []).whereType<String>().toSet(),
      nextCursor: data['nextCursor'] as String?,
    );
  }

  /// 下拉刷新：保留当前分类，重新拉首屏
  Future<void> refresh() async {
    final category = ref.read(feedCategoryProvider);
    try {
      final page = await _fetchPage(category == '全部' ? null : category, null);
      state = AsyncData(FeedState(
        posts: page.posts,
        liked: page.liked,
        nextCursor: page.nextCursor,
        hasMore: page.nextCursor != null,
      ));
    } catch (e, st) {
      // 刷新失败不清空已有内容，仅提示
      if (state.hasValue) rethrow;
      state = AsyncError(e, st);
    }
  }

  /// 滚动到底部时加载下一页
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null ||
        current.loadingMore ||
        !current.hasMore ||
        current.nextCursor == null) {
      return;
    }
    state = AsyncData(current.copyWith(loadingMore: true));
    final category = ref.read(feedCategoryProvider);
    try {
      final page = await _fetchPage(
        category == '全部' ? null : category,
        current.nextCursor,
      );
      state = AsyncData(current.copyWith(
        posts: [...current.posts, ...page.posts],
        liked: {...current.liked, ...page.liked},
        nextCursor: page.nextCursor,
        hasMore: page.nextCursor != null,
        loadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(loadingMore: false));
    }
  }

  /// 点赞切换：先本地乐观更新，失败回滚
  Future<void> toggleLike(Post post) async {
    final current = state.value;
    if (current == null) return;
    final wasLiked = current.liked.contains(post.id);
    final liked = {...current.liked};
    if (wasLiked) {
      liked.remove(post.id);
    } else {
      liked.add(post.id);
    }
    state = AsyncData(current.copyWith(liked: liked));

    try {
      final resp =
          await ApiClient.instance.dio.post('/api/posts/${post.id}/like');
      final serverLiked = (resp.data is Map) && resp.data['liked'] == true;
      final settled = <String>{...(state.value?.liked ?? liked)};
      if (serverLiked) {
        settled.add(post.id);
      } else {
        settled.remove(post.id);
      }
      state = AsyncData(state.value!.copyWith(liked: settled));
    } catch (e) {
      // 回滚
      final rollback = <String>{...(state.value?.liked ?? liked)};
      if (wasLiked) {
        rollback.add(post.id);
      } else {
        rollback.remove(post.id);
      }
      state = AsyncData(state.value!.copyWith(liked: rollback));
      rethrow;
    }
  }
}

class _Page {
  const _Page({
    required this.posts,
    required this.liked,
    required this.nextCursor,
  });

  final List<Post> posts;
  final Set<String> liked;
  final String? nextCursor;
}

/// 把 Dio 异常转成友好提示
String feedErrorMessage(Object e) =>
    ApiClient.errorMessage(e, fallback: '加载失败，请下拉重试');

/// 便于外部读取的常量（分类列表）
const List<String> feedCategories = AppConstants.categories;
