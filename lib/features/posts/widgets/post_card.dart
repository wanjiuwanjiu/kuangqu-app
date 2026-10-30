import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/auth/token_store.dart';
import '../../../core/utils/formatters.dart';
import '../post_model.dart';

/// 分类标签配色（与网页版一致，浅色底 + 彩色字）
const Map<String, Color> _categoryColor = {
  '表白': Color(0xFFEC4899),
  '求助': Color(0xFFD97706),
  '吐槽': Color(0xFF8B5CF6),
  '失物招领': Color(0xFF059669),
  '校园通知': Color(0xFF4A8FD4),
};

/// 帖子卡片
class PostCard extends StatefulWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.liked,
    this.onLike,
    this.onTap,
  });

  final Post post;
  final bool liked;
  final VoidCallback? onLike;
  final VoidCallback? onTap;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final post = widget.post;
    final isLight = theme.brightness == Brightness.light;
    final subColor = theme.textTheme.bodySmall?.color;
    final color = _categoryColor[post.category];

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: softShadow(theme.brightness),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 头部：分类 + 公开 + 昵称 + 时间
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (color != null) _Pill(text: post.category, color: color),
                    if (post.isPublicVisible) ...[
                      const SizedBox(width: 6),
                      _Pill(
                        text: '公开',
                        color: subColor ?? AppColors.lightSubText,
                        subtle: true,
                      ),
                    ],
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (post.displaySub != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                post.displaySub!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 10.5, color: subColor),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      post.relativeTime,
                      style: TextStyle(fontSize: 12, color: subColor),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 正文
                Text(
                  post.content,
                  maxLines: _expanded ? null : 6,
                  overflow: _expanded ? null : TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 15,
                    height: 1.55,
                  ),
                ),
                if (!_expanded && post.content.length > 150)
                  GestureDetector(
                    onTap: () => setState(() => _expanded = true),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '展开',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                // 图片
                if (post.images.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _ImageGrid(images: post.images, isLight: isLight),
                ],

                const SizedBox(height: 12),

                // 底部：点赞 / 评论
                Row(
                  children: [
                    _ActionButton(
                      icon: widget.liked
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: widget.liked ? AppColors.danger : subColor,
                      label: '${post.likeCount}',
                      onTap: widget.onLike,
                    ),
                    const SizedBox(width: 22),
                    _ActionButton(
                      icon: Icons.chat_bubble_outline,
                      color: subColor,
                      label: '${post.commentCount}',
                      onTap: widget.onTap,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color, this.subtle = false});

  final String text;
  final Color color;
  final bool subtle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: subtle
            ? (isLight ? AppColors.lightBg : AppColors.darkBg)
            : color.withValues(alpha: isLight ? 0.10 : 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: subtle
              ? theme.textTheme.bodySmall?.color
              : (isLight ? color : color.withValues(alpha: 0.95)),
        ),
      ),
    );
  }
}

class _ImageGrid extends StatelessWidget {
  const _ImageGrid({required this.images, required this.isLight});

  final List<String> images;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    final bg = isLight ? AppColors.lightBg : AppColors.darkBg;
    final count = images.length.clamp(1, 3);
    // 图片中转接口需要登录态，随请求携带令牌
    final token = TokenStore.instance.accessToken;

    Widget img(String src, double height) => ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: Image.network(
              mediaUrl(src),
              headers:
                  token == null ? null : {'Authorization': 'Bearer $token'},
              fit: BoxFit.cover,
              gaplessPlayback: true,
              frameBuilder: (context, child, frame, wasSync) =>
                  (wasSync || frame != null) ? child : Container(color: bg),
              errorBuilder: (_, _, _) => Container(
                color: bg,
                alignment: Alignment.center,
                child: Icon(
                  Icons.broken_image_outlined,
                  size: 18,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ),
          ),
        );

    if (count == 1) {
      return img(images.first, 190);
    }
    return Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(child: img(images[i], 104)),
        ],
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Icon(
              icon,
              key: ValueKey(icon),
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(fontSize: 13, color: color),
          ),
        ],
      ),
    );
  }
}
