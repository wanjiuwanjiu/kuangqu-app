import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/widgets/skeleton.dart';
import 'feed_controller.dart';
import 'widgets/post_card.dart';

/// 帖子流：分类筛选 + 游标分页 + 下拉刷新 + 上拉加载
class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    // 距底部 300px 时预加载，滚动体验更连贯
    if (_scroll.position.pixels >=
        _scroll.position.maxScrollExtent - 300) {
      ref.read(feedProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = ref.watch(feedCategoryProvider);
    final feed = ref.watch(feedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('校园墙'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // 分类筛选
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              itemCount: feedCategories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final c = feedCategories[i];
                final selected = c == category;
                return _CategoryChip(
                  label: c,
                  selected: selected,
                  onTap: () =>
                      ref.read(feedCategoryProvider.notifier).select(c),
                );
              },
            ),
          ),
          Expanded(
            child: feed.when(
              loading: () => ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                itemCount: 4,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, _) => const PostCardSkeleton(),
              ),
              error: (e, _) => _ErrorView(
                message: feedErrorMessage(e),
                onRetry: () => ref.invalidate(feedProvider),
              ),
              data: (state) {
                if (state.posts.isEmpty) {
                  return _EmptyView(category: category);
                }
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => ref.read(feedProvider.notifier).refresh(),
                  child: ListView.separated(
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    itemCount: state.posts.length + (state.hasMore ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      if (i >= state.posts.length) {
                        // 底部加载提示
                        return Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 8),
                          child: Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                          ),
                        );
                      }
                      final post = state.posts[i];
                      return PostCard(
                        post: post,
                        liked: state.liked.contains(post.id),
                        onLike: () => ref
                            .read(feedProvider.notifier)
                            .toggleLike(post)
                            .catchError((_) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('操作失败，请重试')),
                          );
                        }),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : (isLight ? AppColors.lightCard : AppColors.darkCard),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected
                ? Colors.white
                : theme.textTheme.bodyMedium?.color,
          ),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sub = theme.textTheme.bodySmall?.color;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.22),
        Icon(Icons.article_outlined, size: 48, color: sub?.withValues(alpha: 0.35)),
        const SizedBox(height: 16),
        Center(
          child: Text(
            category == '全部' ? '还没有帖子，来发第一条吧' : '「$category」下暂时没有帖子',
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_outlined,
              size: 44, color: theme.textTheme.bodySmall?.color),
          const SizedBox(height: 14),
          Text(message, style: theme.textTheme.bodySmall),
          const SizedBox(height: 18),
          TextButton(onPressed: onRetry, child: const Text('重新加载')),
        ],
      ),
    );
  }
}
