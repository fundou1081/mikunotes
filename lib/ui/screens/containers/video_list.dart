import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/models/video.dart' as model;
import 'package:mikunotes/core/providers/providers.dart';
import 'package:mikunotes/core/storage/database.dart' as db;
import 'package:mikunotes/ui/screens/video_detail/video_detail_screen.dart';

/// 视频列表 (从 home_screen 抽出, 供 ContainersHome / 容器内视图共用)
class VideoList extends ConsumerWidget {
  const VideoList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosState = ref.watch(videoListProvider);
    final db1 = ref.watch(databaseProvider);

    return videosState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('错误: $e')),
      data: (videos) {
        if (videos.isEmpty) {
          return const _EmptyState();
        }
        return RefreshIndicator(
          onRefresh: () => ref.read(videoListProvider.notifier).load(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final v = videos[index];
              return VideoListItem(
                video: v,
                database: db1,
                onSubtitleDownloaded: () =>
                    ref.read(videoListProvider.notifier).load(),
              );
            },
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.video_library_outlined,
                size: 80, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text('还没有视频',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '粘贴 B站链接即可导入',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 视频卡片 (公开组件,供其他页面复用)
class VideoListItem extends ConsumerStatefulWidget {
  final model.Video video;
  final db.AppDatabase database;
  final VoidCallback onSubtitleDownloaded;
  final VoidCallback? onRemoved; // 移出某容器时调用
  final VoidCallback? onDeleted; // 彻底删除时调用

  const VideoListItem({
    super.key,
    required this.video,
    required this.database,
    required this.onSubtitleDownloaded,
    this.onRemoved,
    this.onDeleted,
  });

  @override
  ConsumerState<VideoListItem> createState() => _VideoListItemState();
}

class _VideoListItemState extends ConsumerState<VideoListItem> {
  bool _downloading = false;
  bool _hasSubtitle = false;

  @override
  void initState() {
    super.initState();
    _checkSubtitle();
  }

  Future<void> _checkSubtitle() async {
    final subs = await widget.database.getSubtitlesForVideo(widget.video.bvid);
    if (mounted) setState(() => _hasSubtitle = subs.isNotEmpty);
  }

  Future<void> _downloadSubtitle() async {
    setState(() => _downloading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final repo = ref.read(videoRepositoryProvider);
      final sub = await repo.downloadAndStoreSubtitle(widget.video.bvid);
      messenger.showSnackBar(
        SnackBar(content: Text('✓ 字幕下载成功: ${sub?.entries.length ?? 0} 条')),
      );
      await _checkSubtitle();
      widget.onSubtitleDownloaded();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('✗ 下载失败: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  void _showActionMenu() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('打开视频详情'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VideoDetailScreen(bvid: widget.video.bvid),
                  ),
                );
              },
            ),
            ListTile(
              leading: _downloading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(_hasSubtitle ? Icons.refresh : Icons.download),
              title: Text(_hasSubtitle ? '重下字幕' : '下载字幕'),
              subtitle: _hasSubtitle ? const Text('已下载，可重新获取') : null,
              onTap: _downloading
                  ? null
                  : () {
                      Navigator.pop(ctx);
                      _downloadSubtitle();
                    },
            ),
            if (widget.onRemoved != null)
              ListTile(
                leading: const Icon(Icons.remove_circle_outline),
                title: const Text('移出此容器'),
                onTap: () async {
                  Navigator.pop(ctx);
                  widget.onRemoved!();
                },
              ),
            if (widget.onDeleted != null || widget.onRemoved != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title:
                    const Text('彻底删除', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(ctx);
                  if (widget.onDeleted != null) {
                    widget.onDeleted!();
                  } else {
                    await ref
                        .read(videoListProvider.notifier)
                        .deleteVideo(widget.video.bvid);
                    widget.onRemoved?.call();
                  }
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('删除', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ref
                      .read(videoListProvider.notifier)
                      .deleteVideo(widget.video.bvid);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.video;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VideoDetailScreen(bvid: v.bvid),
            ),
          );
        },
        onLongPress: _showActionMenu,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (v.coverUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    v.coverUrl,
                    width: 80,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.video_library, size: 40),
                  ),
                )
              else
                const Icon(Icons.video_library, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                '${v.uploader} · ${_formatDuration(v.duration)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                              ),
                              if (v.pageCount > 1)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 0),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondaryContainer,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    '📑 ${v.pageCount}P',
                                    style: TextStyle(
                                      fontSize: 10,
                                      height: 1.4,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSecondaryContainer,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (_downloading)
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 1.5),
                          )
                        else
                          Icon(
                            _hasSubtitle
                                ? Icons.subtitles
                                : Icons.subtitles_outlined,
                            size: 14,
                            color: _hasSubtitle
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outline,
                          ),
                        const SizedBox(width: 4),
                        Text(
                          _hasSubtitle ? '已下载' : '无字幕',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: _hasSubtitle
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primary
                                        : Theme.of(context).colorScheme.outline,
                                    fontSize: 11,
                                  ),
                        ),
                      ],
                    ),
                    // Tag chips (original + AI) - 紧凑样式
                    if (v.allTags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            for (final t in v.allTags)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 0),
                                decoration: BoxDecoration(
                                  color: v.aiTags.contains(t)
                                      ? Theme.of(context)
                                          .colorScheme
                                          .tertiaryContainer
                                      : Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  t,
                                  style: TextStyle(
                                    fontSize: 10,
                                    height: 1.5,
                                    color: v.aiTags.contains(t)
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onTertiaryContainer
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.7),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: _showActionMenu,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDuration(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  if (m >= 60) {
    final h = m ~/ 60;
    final mm = m % 60;
    return '$h:$mm:${s.toString().padLeft(2, '0')}';
  }
  return '$m:${s.toString().padLeft(2, '0')}';
}
