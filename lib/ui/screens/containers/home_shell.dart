import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/bilibili/bilibili_client.dart';
import 'package:mikunotes/core/providers/providers.dart';
import 'package:mikunotes/ui/screens/login/login_screen.dart';
import 'package:mikunotes/ui/screens/containers/containers_home.dart';
import 'package:mikunotes/ui/screens/containers/favorites_tab.dart';
import 'package:mikunotes/ui/screens/containers/import_dialog.dart';
import 'package:mikunotes/ui/screens/containers/import_favorites.dart';
import 'package:mikunotes/ui/screens/containers/import_watch_later.dart';
import 'package:mikunotes/ui/screens/containers/settings_screen.dart';
import 'package:mikunotes/ui/screens/containers/watch_later_tab.dart';

/// 底部 3 Tab 容器: 📂 视频 / ⭐ 收藏夹 / ⏰ 稍后观看
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
  int _index = 0;

  /// 从外部调用切换 Tab
  void switchToTab(int i) {
    if (!mounted) return;
    setState(() => _index = i);
  }

  static const _pages = [
    ContainersHome(),    // 📂 视频
    FavoritesTab(),      // ⭐ 收藏夹
    WatchLaterTab(),     // ⏰ 稍后观看
  ];

  @override
  Widget build(BuildContext context) {
    final bili = ref.watch(bilibiliClientProvider);
    final isLoggedIn = bili.isLoggedIn;
    final user = bili.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MikuNotes'),
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
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showAddMenu(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('导入'),
            )
          : _index == 1
              ? FloatingActionButton.extended(
                  onPressed: () => _openImportFavorites(context),
                  icon: const Icon(Icons.star),
                  label: const Text('导入收藏夹'),
                )
              : FloatingActionButton.extended(
                  onPressed: () => _openImportWatchLater(context),
                  icon: const Icon(Icons.watch_later),
                  label: const Text('导入稍后观看'),
                ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
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
        ],
      ),
    );
  }

  void _login(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _showAddMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('选择导入方式',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.paste),
              title: const Text('手动导入 (单视频)'),
              subtitle: const Text('粘贴链接 / BV号, 会自动下载字幕'),
              onTap: () {
                Navigator.pop(ctx);
                showAddVideoDialog(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('从 B 站收藏夹导入'),
              subtitle: const Text('批量勾选, 不下载字幕'),
              onTap: () {
                Navigator.pop(ctx);
                _openImportFavorites(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.watch_later),
              title: const Text('从 B 站稍后观看导入'),
              subtitle: const Text('批量勾选, 不下载字幕'),
              onTap: () {
                Navigator.pop(ctx);
                _openImportWatchLater(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _openImportFavorites(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ImportFavoritesScreen()),
    );
  }

  void _openImportWatchLater(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ImportWatchLaterScreen()),
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
