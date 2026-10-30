import '../constants.dart';

/// 匿名昵称：由 发布者id + 上下文id（帖子/评论）哈希决定，与网页版算法完全一致
/// 同一人在同一帖子下昵称固定，跨帖变化，无法反推真人
const _adj = [
  '热心', '神秘', '快乐', '腼腆', '勇敢', '安静',
  '元气', '温柔', '酷酷', '佛系', '认真', '迷糊',
];
const _noun = [
  '校友', '同学', '少年', '学姐', '学长',
  '同桌', '路人', '队友', '伙伴', '看客',
];

String anonName(String authorId, String contextId) {
  final s = '$authorId:$contextId';
  var h = 0;
  for (var i = 0; i < s.length; i++) {
    h = (h * 31 + s.codeUnitAt(i)) & 0xFFFFFFFF;
  }
  final a = _adj[h % _adj.length];
  final n = _noun[(h >> 4) % _noun.length];
  final tail = (h % 36).toRadixString(36).toUpperCase();
  return '$a$n·$tail';
}

/// 相对时间展示，与网页版一致
String timeAgo(String iso) {
  final t = DateTime.tryParse(iso)?.toLocal();
  if (t == null) return '';
  final diff = DateTime.now().difference(t);
  final min = diff.inMinutes;
  if (min < 1) return '刚刚';
  if (min < 60) return '$min 分钟前';
  final hour = diff.inHours;
  if (hour < 24) return '$hour 小时前';
  final day = diff.inDays;
  if (day < 30) return '$day 天前';
  return '${t.year}/${t.month}/${t.day}';
}

/// 图片地址：数据库存 Supabase 原始 URL，经本站 /api/media 中转（国内可直连）
String mediaUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  const prefix = 'https://cfksmmccaowbfwpupsuy.supabase.co/storage/v1/object/public/';
  if (url.startsWith(prefix)) {
    return '${AppConstants.apiBaseUrl}/api/media/${url.substring(prefix.length)}';
  }
  return url;
}
