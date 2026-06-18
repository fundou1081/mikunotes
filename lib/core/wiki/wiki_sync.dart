import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/events/video_events.dart';
import 'package:mikunotes/core/wiki/wiki_generator.dart';
import 'package:mikunotes/core/wiki/wiki_storage.dart';
import 'package:mikunotes/core/providers/providers.dart' show databaseProvider;

/// Wiki Sync: 订阅 VideoEventBus, 把变更写入 .md 文件
///
/// 设计:
/// - Debounce 1s: 短时间内多个事件合并成一次写
/// - 写失败 swallow: 旁路, 不影响业务
/// - 启动时一次性重建所有 .md (兜底)
class WikiSync {
    final Ref _ref;
    final Set<String> _dirtyBvids = {};
    Timer? _debounceTimer;
    StreamSubscription<VideoEvent>? _sub;
    bool _running = false;
    bool _started = false;

    WikiSync(this._ref);

    /// 启动监听
    void start() {
        if (_started) return;
        _started = true;
        final bus = _ref.read(videoEventBusProvider);
        _sub = bus.events.listen(_onEvent, onError: (_) {});
        // 启动后延迟 5s 做一次全量重建 (兜底)
        Timer(const Duration(seconds: 5), _fullRebuild);
    }

    /// 停止监听
    void stop() {
        _sub?.cancel();
        _sub = null;
        _debounceTimer?.cancel();
        _debounceTimer = null;
        _started = false;
    }

    void _onEvent(VideoEvent e) {
        _dirtyBvids.add(e.bvid);
        _scheduleFlush();
    }

    void _scheduleFlush() {
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(seconds: 1), _flush);
    }

    Future<void> _flush() async {
        if (_dirtyBvids.isEmpty) return;
        final bvids = _dirtyBvids.toList();
        _dirtyBvids.clear();

        final storage = _ref.read(wikiStorageProvider);
        final generator = _ref.read(wikiGeneratorProvider);

        for (final bvid in bvids) {
            try {
                final md = await generator.generateVideoMarkdown(bvid);
                if (md == null) continue;
                final group = await _ref.read(databaseProvider).getVideoGroup(bvid);
                final title = group?.title ?? bvid;
                await storage.writeVideoMarkdown(bvid, title, md);
            } catch (_) {
                // 写失败不影响业务
            }
        }
        // 索引总是写
        try {
            final indexMd = await generator.generateIndexMarkdown();
            await storage.writeFile('index.md', indexMd);
        } catch (_) {}
    }

    /// 全量重建: 用于首次启动 / 事件漏发
    Future<void> _fullRebuild() async {
        if (_running) return;
        _running = true;
        try {
            final db = _ref.read(databaseProvider);
            final groups = await db.getAllVideoGroups();
            final storage = _ref.read(wikiStorageProvider);
            final generator = _ref.read(wikiGeneratorProvider);
            for (final g in groups) {
                try {
                    final md = await generator.generateVideoMarkdown(g.bvid);
                    if (md == null) continue;
                    await storage.writeVideoMarkdown(g.bvid, g.title, md);
                } catch (_) {}
            }
            try {
                final indexMd = await generator.generateIndexMarkdown();
                await storage.writeFile('index.md', indexMd);
            } catch (_) {}
        } finally {
            _running = false;
        }
    }
}

final wikiSyncProvider = Provider<WikiSync>((ref) {
    final sync = WikiSync(ref);
    ref.onDispose(sync.stop);
    return sync;
});
