import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/auth/session.dart';

/// 主页外壳：底部三栏导航（帖子 / 消息 / 我的）
/// 模块1 仅占位，后续模块逐个填充
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pages = [
      _PlaceholderTab(
        icon: Icons.article_outlined,
        title: '帖子',
        subtitle: '帖子流将在下一个模块开放',
      ),
      _PlaceholderTab(
        icon: Icons.notifications_none,
        title: '消息',
        subtitle: '公告与互动消息将在后续模块开放',
      ),
      _ProfileTab(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      extendBody: true,
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          // 毛玻璃底栏，贴近 iOS 原生质感
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: NavigationBar(
            height: 56,
            elevation: 0,
            backgroundColor:
                theme.scaffoldBackgroundColor.withValues(alpha: 0.75),
            indicatorColor: AppColors.primary.withValues(alpha: 0.12),
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.article_outlined),
                selectedIcon: Icon(Icons.article, color: AppColors.primary),
                label: '帖子',
              ),
              NavigationDestination(
                icon: Icon(Icons.notifications_none),
                selectedIcon:
                    Icon(Icons.notifications, color: AppColors.primary),
                label: '消息',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person, color: AppColors.primary),
                label: '我的',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 48,
                color: theme.textTheme.bodySmall?.color
                    ?.withValues(alpha: 0.35)),
            const SizedBox(height: 16),
            Text(subtitle, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// 「我的」页：模块1 先放账号信息与退出登录，隐私设置等后续模块补充
class _ProfileTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = ref.watch(sessionProvider).value;
    final profile = session is SessionAuthed ? session.profile : null;

    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              boxShadow: softShadow(theme.brightness),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    (profile?.nickname.isNotEmpty == true
                            ? profile!.nickname
                            : '同')
                        .substring(0, 1),
                    style: const TextStyle(
                      fontSize: 22,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?.nickname ?? '',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile == null
                            ? ''
                            : '${profile.realName} · ${profile.className}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () =>
                ref.read(sessionProvider.notifier).logout(),
            icon: const Icon(Icons.logout, color: AppColors.danger, size: 20),
            label: const Text('退出登录',
                style: TextStyle(color: AppColors.danger, fontSize: 15)),
          ),
        ],
      ),
    );
  }
}
