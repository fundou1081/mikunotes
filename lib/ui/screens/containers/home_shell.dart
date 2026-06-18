import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/bilibili/bilibili_client.dart';
import 'package:mikunotes/core/providers/app_mode_provider.dart';
import 'package:mikunotes/core/providers/providers.dart';
import 'package:mikunotes/ui/screens/login/login_screen.dart';
import 'package:mikunotes/ui/screens/containers/containers_home.dart';
import 'package:mikunotes/ui/screens/containers/favorites_tab.dart';
import 'package:mikunotes/ui/screens/containers/import_dialog.dart';
import 'package:mikunotes/ui/screens/containers/import_favorites.dart';
import 'package:mikunotes/ui/screens/containers/batch_import.dart';
import 'package:mikunotes/ui/screens/containers/settings_screen.dart';
import 'package:mikunotes/ui/screens/containers/upmaster_search.dart';
import 'package:mikunotes/ui/screens/containers/upmasters_tab.dart';
import 'package:mikunotes/ui/screens/containers/watch_later_tab.dart';
import 'package:mikunotes/ui/screens/insight/graph_visualization.dart';
import 'package:mikunotes/ui/screens/insight/wiki_viewer.dart';
import 'package:mikunotes/ui/screens/insight/wiki_chat.dart';

/// 底部 4 Tab 容器: 📂 视频 / ⭐ 收藏夹 / ⏰ 稍后观看 / 👤 UP 主
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  /// 静态 GlobalKey, 用于从其他页面切换 Tab
  /// 使用: HomeShell.tabKey.currentState?.switchToTab(1);
  static final GlobalKey<_HomeShellState> tabKey =
      GlobalKey<_HomeShellState>();

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _videoIndex = 0;
  int _insightIndex = 0;

  /// 从外部调用切换 Tab (仅视频管理模式下有效)
  void switchToTab(int i) {
    if (!mounted) return;
    setState(() => _videoIndex = i);
  }

  static const _videoPages = [
    ContainersHome(),    // 📂 视频
    FavoritesTab(),      // ⭐ 收藏夹
    WatchLaterTab(),     // ⏰ 稍后观看
    UpMastersTab(),      // 👤 UP 主
  ];

  static const _insightPages = [
    WikiViewer(),           // 📚 浏览 Wiki
    WikiChat(),             // 💬 对话洞察
    GraphVisualization(),   // 📊 图可视化 (待开发)
  ];

  void _switchMode() {
    final current = ref.read(appModeProvider);
    ref.read(appModeProvider.notifier).state = current == AppMode.videoManagement
        ? AppMode.insight
        : AppMode.videoManagement;
  }

  @override
  Widget build(BuildContext context) {
    final bili = ref.watch(bilibiliClientProvider);
    final isLoggedIn = bili.isLoggedIn;
    final user = bili.user;
    final mode = ref.watch(appModeProvider);
    final isInsight = mode == AppMode.insight;
    final index = isInsight ? _insightIndex : _videoIndex;

    return Scaffold(
      appBar: AppBar(
        // ⭐ 左上角模式切换按钮
        leadingWidth: 56,
        leading: _ModeToggleButton(
          mode: mode,
          onToggle: _switchMode,
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isInsight ? '洞察 · MikuNotes' : 'MikuNotes',
              style: TextStyle(
                fontSize: 18,
                color: isInsight
                    ? Theme.of(context).colorScheme.primary
                    : null,
                fontWeight: isInsight ? FontWeight.bold : null,
              ),
            ),
            if (isInsight) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'WIKI',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (!isLoggedIn)
            TextButton.icon(
              onPressed: () => _login(context),
              icon: const Icon(Icons.login, size: 18),
              label: const Text('登录'),
            )
          else if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: TextButton(
                onPressed: () => _showUserMenu(context, ref),
                child: Text(
                  '@${user.uname}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _openSettings(context),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: isInsight
            ? IndexedStack(
                key: const ValueKey('insight'),
                index: _insightIndex,
                children: _insightPages,
              )
            : IndexedStack(
                key: const ValueKey('video'),
                index: _videoIndex,
                children: _videoPages,
              ),
      ),
      floatingActionButton: isInsight
          ? null  // 洞察模式不需要 FAB
          : (_videoIndex == 0
              ? FloatingActionButton.extended(
                  onPressed: () => _openManualImport(context),
                  icon: const Icon(Icons.add),
                  label: const Text('导入'),
                )
              : _videoIndex == 1
                  ? FloatingActionButton.extended(
                      onPressed: () => _openImportFavorites(context),
                      icon: const Icon(Icons.star),
                      label: const Text('导入收藏夹'),
                    )
                  : _videoIndex == 2
                      ? FloatingActionButton.extended(
                          onPressed: () => _openImportWatchLater(context),
                          icon: const Icon(Icons.watch_later),
                          label: const Text('导入稍后观看'),
                        )
                      : FloatingActionButton.extended(
                          onPressed: () => _openUpMasterSearch(context),
                          icon: const Icon(Icons.search),
                          label: const Text('搜索 UP 主'),
                        )),
      bottomNavigationBar: isInsight
          ? NavigationBar(
              selectedIndex: _insightIndex,
              onDestinationSelected: (i) => setState(() => _insightIndex = i),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.description_outlined),
                  selectedIcon: Icon(Icons.description),
                  label: 'Wiki',
                ),
                NavigationDestination(
                  icon: Icon(Icons.chat_outlined),
                  selectedIcon: Icon(Icons.chat),
                  label: '对话',
                ),
                NavigationDestination(
                  icon: Icon(Icons.account_tree_outlined),
                  selectedIcon: Icon(Icons.account_tree),
                  label: '图谱',
                ),
              ],
            )
          : NavigationBar(
              selectedIndex: _videoIndex,
              onDestinationSelected: (i) => setState(() => _videoIndex = i),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.folder_outlined),
                  selectedIcon: Icon(Icons.folder),
                  label: '视频',
                ),
                NavigationDestination(
                  icon: Icon(Icons.star_border),
                  selectedIcon: Icon(Icons.star),
                  label: '收藏夹',
                ),
                NavigationDestination(
                  icon: Icon(Icons.watch_later_outlined),
                  selectedIcon: Icon(Icons.watch_later),
                  label: '稍后观看',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'UP 主',
                ),
              ],
            ),
    );
  }

  void _login(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _openManualImport(BuildContext context) {
    showAddVideoDialog(context, ref);
  }

  void _openUpMasterSearch(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const UpMasterSearchScreen()),
    );
  }

  void _openImportFavorites(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ImportFavoritesScreen()),
    );
  }

  void _openImportWatchLater(BuildContext context) {
    final r = ref;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BatchImportScreen(config: BatchImportConfig(
          appBarTitle: '从稍后观看导入',
          hintText: '稍后观看',
          resolveContainerId: () async {
            final db = r.read(databaseProvider);
            final c = await (db.select(db.containers)
                  ..where((c) => c.type.equals('watch_later')))
                .getSingleOrNull();
            if (c == null) throw Exception('稍后观看容器创建失败');
            return c.id;
          },
          loadPage: (page, ps) async {
            final bili = r.read(bilibiliClientProvider);
            final result = await bili.getWatchLaterWithInfo(pn: page, ps: ps);
            final videos = (result['videos'] as List)
                .map<Map<String, String>>((m) {
                  final mm = m as Map;
                  return {for (final e in mm.entries) e.key.toString(): e.value.toString()};
                });
            return videos.toList();
          },
          // 首次不自动 sync, 用户点 AppBar 的\"同步\"按钮才拉
          onSync: () => r.read(containerListProvider.notifier).syncWatchLater(),
        )),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void _showUserMenu(BuildContext context, WidgetRef ref) {
    final bili = ref.read(bilibiliClientProvider);
    final user = bili.user;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (user != null) ...[
              ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                      user.face.isNotEmpty ? NetworkImage(user.face) : null,
                  child: user.face.isEmpty
                      ? Text(user.uname.isNotEmpty ? user.uname[0] : '?')
                      : null,
                ),
                title: Text(user.uname,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('UID: ${user.mid} · Lv${user.level}'),
              ),
              const Divider(height: 1),
            ],
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('设置'),
              onTap: () {
                Navigator.pop(ctx);
                _openSettings(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('退出登录', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(ctx);
                await ref.read(bilibiliClientProvider.notifier).logout();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已退出登录')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// ⭐ 左上角模式切换按钮 — 视频管理 ↔ 洞察
class _ModeToggleButton extends StatelessWidget {
  final AppMode mode;
  final VoidCallback onToggle;
  const _ModeToggleButton({required this.mode, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final isInsight = mode == AppMode.insight;
    final color = isInsight
        ? Theme.of(context).colorScheme.primary
        : null;
    return IconButton(
      tooltip: isInsight ? '切换到视频管理' : '切换到洞察模式',
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, anim) => RotationTransition(
          turns: Tween(begin: 0.5, end: 1.0).animate(anim),
          child: FadeTransition(opacity: anim, child: child),
        ),
        child: Icon(
          isInsight
              ? Icons.folder_special_outlined
              : Icons.lightbulb_outline,
          key: ValueKey(isInsight),
          color: color,
        ),
      ),
      onPressed: onToggle,
    );
  }
}
