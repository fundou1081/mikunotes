import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App 模式: 视频管理 vs 洞察
enum AppMode {
  /// 视频管理模式 (默认) — 4 个 tab: 视频/收藏夹/稍后观看/UP主
  videoManagement,

  /// 洞察模式 — 3 个 tab: Wiki 浏览 / 多轮对话 / 洞察列表
  insight,
}

extension AppModeX on AppMode {
  String get title => switch (this) {
        AppMode.videoManagement => 'MikuNotes',
        AppMode.insight => '洞察 · MikuNotes',
      };

  String get description => switch (this) {
        AppMode.videoManagement => '视频管理模式',
        AppMode.insight => 'LLM Wiki 洞察模式',
      };
}

final appModeProvider = StateProvider<AppMode>((ref) => AppMode.videoManagement);
