import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/providers/providers.dart';
import 'package:mikunotes/core/storage/database.dart' as db hide Container;
import 'package:drift/drift.dart' as drift show Value;
import 'package:mikunotes/ui/screens/containers/undo_snackbar.dart';
import 'package:mikunotes/ui/screens/containers/video_list.dart';

/// 进入某个收藏夹文件夹 — 显示已导入的视频
class FavoriteFolderScreen extends ConsumerWidget {
  final int containerId;
  final String containerName;
  final int totalCount;

  const FavoriteFolderScreen({
    super.key,
    required this.containerId,
    required this.containerName,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosState = ref.watch(videosInContainerProvider(containerId));
    final containers = ref.watch(containerListProvider);
    final db1 = ref.watch(databaseProvider);

    final currentContainer = containers.maybeWhen(
      data: (list) => list.firstWhere(
        (c) => c.id == containerId,
        orElse: () => ContainerInfo(
          id: containerId,
          type: ContainerType.favorite,
          externalId: null,
          name: containerName,
          totalCount: totalCount,
          importedCount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ),
      orElse: () => ContainerInfo(
        id: containerId,
        type: ContainerType.favorite,
        externalId: null,
        name: containerName,
        totalCount: totalCount,
        importedCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(containerName),
        actions: [
          // 下载全部字幕按钮 (Phase C)
          if (videosState.maybeWhen(
            data: (vs) => vs.isNotEmpty,
            orElse: () => false,
          ))
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: '下载全部字幕',
              onPressed: () => _downloadAllSubtitles(context, ref),
            ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'remove_all') {
                await _removeAll(context, ref);
              }
            },
            itemBuilder: (c) => [
              const PopupMenuItem(
                value: 'remove_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: Colors.red),
                    SizedBox(width: 8),
                    Text('移出此收藏夹所有视频',
                        style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: videosState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('错误: $e')),
        data: (videos) {
          if (videos.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.folder_open, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text('已导入 0 / $totalCount', style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    const Text('Phase B 会加导入入口',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            );
          }
          return Column(
            children: [
              // 顶部统计
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Row(
                  children: [
                    Text(
                      '已导入 ${videos.length} / $totalCount',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: totalCount == 0 ? 0 : videos.length / totalCount,
                          minHeight: 6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => ref
                      .read(videosInContainerProvider(containerId).notifier)
                      .load(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: videos.length,
                    itemBuilder: (context, index) {
                      final v = videos[index];
                      return VideoListItem(
                        video: v,
                        database: db1,
                        onSubtitleDownloaded: () => ref
                            .read(videosInContainerProvider(containerId)
                                .notifier)
                            .load(),
                        onRemoved: () => _removeFromContainer(
                            context, ref, v.bvid),
                        onDeleted: () => _deleteVideo(context, ref, v.bvid),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _removeFromContainer(
      BuildContext context, WidgetRef ref, String bvid) async {
    final db1 = ref.read(databaseProvider);
    // 备份: 查原有的 addedAt 以便撤销
    final originalRow = await (db1.select(db1.containerVideos)
          ..where((cv) => cv.containerId.equals(containerId))
          ..where((cv) => cv.bvid.equals(bvid)))
        .getSingleOrNull();
    if (originalRow == null) return;
    final originalAddedAt = originalRow.addedAt;

    await db1.removeVideoFromContainer(containerId, bvid);
    ref.read(videosInContainerProvider(containerId).notifier).load();
    ref.read(containerListProvider.notifier).load();
    showUndoSnackBar(
      context,
      '✓ 已移出此收藏夹',
      onUndo: () async {
        await db1.addVideoToContainer(containerId, bvid, addedAt: originalAddedAt);
        ref.read(videosInContainerProvider(containerId).notifier).load();
        ref.read(containerListProvider.notifier).load();
      },
    );
  }

  Future<void> _deleteVideo(
      BuildContext context, WidgetRef ref, String bvid) async {
    final messenger = ScaffoldMessenger.of(context);
    final db1 = ref.read(databaseProvider);
    // 备份: 视频、字幕、总结
    final video = await db1.getVideo(bvid);
    final subs = await db1.getSubtitlesForVideo(bvid);
    final sums = await db1.getSummariesForVideo(bvid);
    final containerLinks = await db1.getContainersForBvid(bvid);

    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('彻底删除?'),
        content: const Text('将从所有容器中删除,并删除其总结/字幕/对话。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(videoListProvider.notifier).deleteVideo(bvid);
    ref.read(videosInContainerProvider(containerId).notifier).load();
    ref.read(containerListProvider.notifier).load();
    showUndoSnackBar(
      context,
      '✓ 已彻底删除',
      onUndo: () async {
        if (video == null) return;
        // 恢复视频
        await db1.upsertVideo(db.VideosCompanion.insert(
          bvid: video.bvid,
          page: 1,
          aid: video.aid,
          cid: drift.Value(0),
          partName: drift.Value(''),
          partTitle: drift.Value(''),
          partCover: drift.Value(''),
          duration: drift.Value(video.duration),
          addedAt: video.addedAt,
        ));
        // 恢复字幕
        for (final s in subs) {
          await db1.upsertSubtitle(db.SubtitlesCompanion.insert(
            bvid: s.bvid,
            page: drift.Value(s.page),
            language: s.language,
            rawJson: s.rawJson,
            plainText: s.plainText,
            charCount: drift.Value(s.charCount),
            entryCount: drift.Value(s.entryCount),
            downloadedAt: s.downloadedAt,
          ));
        }
        // 恢复总结
        for (final s in sums) {
          await db1.saveSummary(db.SummariesCompanion.insert(
            id: s.id,
            bvid: s.bvid,
            title: drift.Value(s.title),
            type: s.type,
            content: s.content,
            modelUsed: drift.Value(s.modelUsed),
            promptUsed: drift.Value(s.promptUsed),
            targetTopic: drift.Value(s.targetTopic),
            createdAt: s.createdAt,
          ));
        }
        // 恢复容器关联
        for (final c in containerLinks) {
          await db1.addVideoToContainer(c.id, bvid);
        }
        ref.read(videosInContainerProvider(containerId).notifier).load();
        ref.read(containerListProvider.notifier).load();
        ref.read(videoListProvider.notifier).load();
        messenger.showSnackBar(
          const SnackBar(content: Text('✓ 已恢复')),
        );
      },
    );
  }

  Future<void> _removeAll(BuildContext context, WidgetRef ref) async {
    final db1 = ref.read(databaseProvider);
    final bvids = await db1.getBvidsInContainer(containerId);
    if (bvids.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('该收藏夹无视频')));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('移出所有视频?'),
        content: Text('将从此收藏夹移除 ${bvids.length} 个视频 (不会删除视频本身)。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('移出'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    for (final bvid in bvids) {
      await db1.removeVideoFromContainer(containerId, bvid);
    }
    ref.read(videosInContainerProvider(containerId).notifier).load();
    ref.read(containerListProvider.notifier).load();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('✓ 已移出 ${bvids.length} 个视频')));
    }
  }

  /// 批量下载字幕 (Phase C)
  Future<void> _downloadAllSubtitles(
      BuildContext context, WidgetRef ref) async {
    final db1 = ref.read(databaseProvider);
    final bvids = await db1.getBvidsInContainer(containerId);
    if (bvids.isEmpty) return;

    // 过滤出没有字幕的
    final needsDownload = <String>[];
    for (final bvid in bvids) {
      final subs = await db1.getSubtitlesForVideo(bvid);
      if (subs.isEmpty) needsDownload.add(bvid);
    }

    if (needsDownload.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('所有视频都已有字幕 ✓')),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('下载全部字幕?'),
        content: Text(
            '将逐个下载 ${needsDownload.length} 个视频的字幕。\n\n可能需要几分钟。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('开始下载'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!context.mounted) return;

    // 进度 dialog
    final progressNotifier = ValueNotifier<int>(0);
    int successCount = 0;
    int failCount = 0;
    String? failDetail;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: const Text('下载字幕中...'),
        content: ValueListenableBuilder<int>(
          valueListenable: progressNotifier,
          builder: (_, progress, __) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$progress / ${needsDownload.length}'),
                const SizedBox(height: 12),
                SizedBox(
                  width: 240,
                  child: LinearProgressIndicator(
                    value: needsDownload.isEmpty
                        ? 0
                        : progress / needsDownload.length,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 12),
                Text('成功 $successCount  失败 $failCount',
                    style: const TextStyle(fontSize: 12)),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              progressNotifier.value = -1; // 标记取消
            },
            child: const Text('取消'),
          ),
        ],
      ),
    );

    final repo = ref.read(videoRepositoryProvider);
    for (var i = 0; i < needsDownload.length; i++) {
      // 检查是否被取消
      if (progressNotifier.value == -1) {
        Navigator.of(context, rootNavigator: true).pop();
        break;
      }
      final bvid = needsDownload[i];
      try {
        await repo.downloadAndStoreSubtitle(bvid);
        successCount++;
      } catch (e) {
        failCount++;
        failDetail = '$bvid: $e';
      }
      progressNotifier.value = i + 1;
    }

    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      ref
          .read(videosInContainerProvider(containerId).notifier)
          .load();
      ref.read(containerListProvider.notifier).load();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ 成功 $successCount, 失败 $failCount'
              '${failDetail != null ? '\n首个失败: $failDetail' : ''}'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}
