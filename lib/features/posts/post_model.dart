import '../../core/utils/formatters.dart';

/// 帖子数据（字段与后端 posts 表 / 接口返回一致）
class Post {
  const Post({
    required this.id,
    required this.authorId,
    required this.content,
    required this.category,
    required this.images,
    required this.isAnonymous,
    required this.createdAt,
    this.authorNickname,
    this.authorSub,
    this.visibility,
    this.commentCount = 0,
    this.likeCount = 0,
  });

  final String id;
  final String authorId;
  final String content;
  final String category;
  final List<String> images;
  final bool isAnonymous;
  final String createdAt;
  final String? authorNickname;
  final String? authorSub;
  final String? visibility;
  final int commentCount;
  final int likeCount;

  bool get isPublicVisible => visibility == 'public';

  /// 展示名：匿名一律随机昵称；公开按用户隐私设置显示昵称 +（可选）真实姓名·班级
  String get displayName =>
      isAnonymous ? anonName(authorId, id) : (authorNickname ?? anonName(authorId, id));

  String? get displaySub => isAnonymous ? null : authorSub;

  String get relativeTime => timeAgo(createdAt);

  factory Post.fromJson(Map<String, dynamic> j) {
    int countOf(dynamic v) {
      if (v is List && v.isNotEmpty && v.first is Map) {
        final c = (v.first as Map)['count'];
        if (c is num) return c.toInt();
      }
      return 0;
    }

    return Post(
      id: j['id'] as String,
      authorId: j['author_id'] as String? ?? '',
      content: j['content'] as String? ?? '',
      category: j['category'] as String? ?? '',
      images: (j['images'] as List?)?.whereType<String>().toList() ?? const [],
      // 后端默认匿名，仅在明确为 false 时视为公开
      isAnonymous: j['is_anonymous'] != false,
      createdAt: j['created_at'] as String? ?? '',
      authorNickname: j['author_nickname'] as String?,
      authorSub: j['author_sub'] as String?,
      visibility: j['visibility'] as String?,
      commentCount: countOf(j['comments']),
      likeCount: countOf(j['likes']),
    );
  }
}
