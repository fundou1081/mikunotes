import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/providers/providers.dart';
import 'package:mikunotes/core/models/video.dart' as model;
import 'package:mikunotes/ui/screens/video_detail/video_detail_screen.dart';

/// 列出指定 UP 主的视频 (从 [[uploader:xxx]] 链接跳转过来)
class UpMasterListScreen extends ConsumerStatefulWidget {
    final String uploaderName;

    const UpMasterListScreen({super.key, required this.uploaderName});

    @override
    ConsumerState<UpMasterListScreen> createState() => _UpMasterListScreenState();
}

class _UpMasterListScreenState extends ConsumerState<UpMasterListScreen> {
    List<model.Video> _videos = [];
    bool _loading = true;

    @override
    void initState() {
        super.initState();
        _load();
    }

    Future<void> _load() async {
        setState(() => _loading = true);
        try {
            final repo = ref.read(videoRepositoryProvider);
            final all = await repo.getAllVideos();
            _videos = all.where((v) => v.uploader == widget.uploaderName).toList();
        } finally {
            if (mounted) setState(() => _loading = false);
        }
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: Text('@${widget.uploaderName}'),
            ),
            body: _loading
                ? const Center(child: CircularProgressIndicator())
                : _videos.isEmpty
                    ? Center(
                        child: Text('没有找到 @${widget.uploaderName} 的视频'),
                    )
                    : Column(
                        children: [
                            Container(
                                padding: const EdgeInsets.all(12),
                                color: Theme.of(context).colorScheme.primaryContainer,
                                child: Row(
                                    children: [
                                        const Icon(Icons.person),
                                        const SizedBox(width: 8),
                                        Expanded(
                                            child: Text(
                                                '@${widget.uploaderName} 共 ${_videos.length} 个视频',
                                                style: TextStyle(
                                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                                ),
                                            ),
                                        ),
                                    ],
                                ),
                            ),
                            Expanded(
                                child: ListView.separated(
                                    itemCount: _videos.length,
                                    separatorBuilder: (_, __) => const Divider(height: 1),
                                    itemBuilder: (ctx, i) {
                                        final v = _videos[i];
                                        return ListTile(
                                            leading: v.coverUrl.isNotEmpty
                                                ? ClipRRect(
                                                    borderRadius: BorderRadius.circular(4),
                                                    child: Image.network(
                                                        v.coverUrl,
                                                        width: 60,
                                                        height: 40,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (_, __, ___) =>
                                                            const Icon(Icons.video_library, size: 32),
                                                    ),
                                                )
                                                : const Icon(Icons.video_library, size: 32),
                                            title: Text(v.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                                            subtitle: Text(
                                                '${v.bvid} · ${_formatDuration(v.duration)}',
                                                style: const TextStyle(fontSize: 11),
                                            ),
                                            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                                            onTap: () {
                                                Navigator.of(context).push(MaterialPageRoute(
                                                    builder: (_) => VideoDetailScreen(bvid: v.bvid),
                                                ));
                                            },
                                        );
                                    },
                                ),
                            ),
                        ],
                    ),
        );
    }

    String _formatDuration(int sec) {
        if (sec <= 0) return '?';
        final h = sec ~/ 3600;
        final m = (sec % 3600) ~/ 60;
        if (h > 0) return '${h}h${m}m';
        return '${m}m';
    }
}
