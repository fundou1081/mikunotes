import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/bilibili/bilibili_client.dart';
import 'package:mikunotes/core/providers/providers.dart';
import 'package:mikunotes/ui/screens/login/login_screen.dart';
import 'package:mikunotes/ui/screens/containers/containers_home.dart';
import 'package:mikunotes/ui/screens/containers/favorites_tab.dart';
import 'package:mikunotes/ui/screens/containers/import_dialog.dart';
import 'package:mikunotes/ui/screens/containers/settings_screen.dart';
import 'package:mikunotes/ui/screens/containers/watch_later_tab.dart';

/// 底部 3 Tab 容器: 📂 视频 / ⭐ 收藏夹 / ⏰ 稍后观看
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

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
              onPressed: () => showAddVideoDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('导入视频'),
            )
          : null,
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
