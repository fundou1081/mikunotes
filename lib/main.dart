import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/wiki/wiki_sync.dart';
import 'package:mikunotes/ui/theme/app_theme.dart';
import 'package:mikunotes/ui/screens/containers/home_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MikuNotesApp()));
}

class MikuNotesApp extends ConsumerStatefulWidget {
  const MikuNotesApp({super.key});

  @override
  ConsumerState<MikuNotesApp> createState() => _MikuNotesAppState();
}

class _MikuNotesAppState extends ConsumerState<MikuNotesApp> {
  @override
  void initState() {
    super.initState();
    // ⭐ 启动 LLM Wiki 后台同步
    Future.microtask(() {
      try {
        ref.read(wikiSyncProvider).start();
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MikuNotes',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: HomeShell(key: HomeShell.tabKey),
    );
  }
}
