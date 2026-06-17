import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/models/video.dart' as model;
import 'package:mikunotes/core/providers/providers.dart';
import 'package:mikunotes/core/storage/database.dart' as db;
import 'package:mikunotes/ui/screens/containers/containers_home.dart';
import 'package:mikunotes/ui/screens/containers/video_list.dart';

/// 👤 UP 主 Tab - 视频列表 + 顶部 chip 过滤 (全部 / 各 UP主)
class UpMastersTab extends ConsumerStatefulWidget {
  const UpMastersTab({super.key});

  @override
  ConsumerState<UpMastersTab> createState() => _UpMastersTabState();
}

class _UpMastersTabState extends ConsumerState<UpMastersTab> {
  int? _selectedUpMasterId; // null = 全部

  @override
  Widget build(BuildContext context) {
    final upMastersState = ref.watch(upMasterListProvider);
    final cs = Theme.of(context).colorScheme;

    final upMasters = upMastersState.maybeWhen(
      data: (list) => list,
      orElse: () => <UpMasterInfo>[],
    );
    final totalImported = upMasters.fold<int>(0, (a, b) => a + b.importedCount);

    return Column(
      children: [
        // 顶部操作栏
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text('👤 UP 主',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(width: 8),
              Text('(关注 ${upMasters.length} / 已入库 $totalImported)',
                  style: TextStyle(fontSize: 12, color: cs.outline)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: '刷新',
                onPressed: () => ref.read(upMasterListProvider.notifier).load(),
              ),
            ],
          ),
        ),
        // 顶部 chip 过滤
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              _buildChip(
                context,
                label: '全部 $totalImported',
                avatarUrl: null,
                value: null,
              ),
              ...upMasters.map((um) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _buildChip(
                      context,
                      label: '${um.name} (${um.importedCount})',
                      avatarUrl: um.face,
                      value: um.id,
                    ),
                  )),
            ],
          ),
        ),
        const Divider(height: 1),
        // 视频列表
        Expanded(
          child: _selectedUpMasterId == null
              ? const _AllUpMasterList()
              : VideosInContainerView(containerId: _selectedUpMasterId!),
        ),
      ],
    );
  }

  Widget _buildChip(BuildContext context,
      {required String label, String? avatarUrl, required int? value}) {
    final selected = _selectedUpMasterId == value;
    return FilterChip(
      avatar: avatarUrl != null && avatarUrl.isNotEmpty
          ? CircleAvatar(backgroundImage: NetworkImage(avatarUrl), radius: 10)
          : null,
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) => setState(() => _selectedUpMasterId = value),
    );
  }
}

/// "全部" 视图: 跨所有 UP 主容器的视频
class _AllUpMasterList extends ConsumerWidget {
  const _AllUpMasterList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosState = ref.watch(allUpMasterVideosProvider);
    final db1 = ref.watch(databaseProvider);

    return videosState.when(
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
                  const Icon(Icons.person_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('还没有 UP 主视频', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  const Text('导入视频时会自动按 UP 主分组',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.read(allUpMasterVideosProvider.notifier).load();
            ref.read(upMasterListProvider.notifier).load();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final v = videos[index];
              return VideoListItem(
                video: v,
                database: db1,
                onSubtitleDownloaded: () {
                  ref.read(allUpMasterVideosProvider.notifier).load();
                  ref.read(upMasterListProvider.notifier).load();
                },
                onDeleted: () async {
                  await ref
                      .read(videoListProvider.notifier)
                      .deleteVideo(v.bvid);
                  ref.read(allUpMasterVideosProvider.notifier).load();
                  ref.read(upMasterListProvider.notifier).load();
                },
              );
            },
          ),
        );
      },
    );
  }
}
