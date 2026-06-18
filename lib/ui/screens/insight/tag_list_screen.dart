import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/providers/providers.dart';
import 'package:mikunotes/core/models/video.dart' as model;
import 'package:mikunotes/ui/screens/video_detail/video_detail_screen.dart';

/// 列出所有含指定 tag 的视频 (从 [[tag:xxx]] 链接跳转过来)
class TagListScreen extends ConsumerStatefulWidget {
    final String tag;

    const TagListScreen({super.key, required this.tag});

    @override
    ConsumerState<TagListScreen> createState() => _TagListScreenState();
}

class _TagListScreenState extends ConsumerState<TagListScreen> {
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
            _videos = all.where((v) {
                return v.allTags.contains(widget.tag);
            }).toList();
        } finally {
            if (mounted) setState(() => _loading = false);
        }
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: Text('#${widget.tag}'),
            ),
            body: _loading
                ? const Center(child: CircularProgressIndicator())
                : _videos.isEmpty
                    ? Center(
                        child: Text('没有视频含 #${widget.tag} 标签'),
                    )
                    : Column(
                        children: [
                            // 顶部统计
                            Container(
                                padding: const EdgeInsets.all(12),
                                color: Theme.of(context).colorScheme.primaryContainer,
                                child: Row(
                                    children: [
                                        const Icon(Icons.label),
                                        const SizedBox(width: 8),
                                        Expanded(
                                            child: Text(
                                                '共 ${_videos.length} 个视频含 #${widget.tag}',
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
                                                '${v.bvid} · ${v.uploader}',
                                                style: const TextStyle(fontSize: 11),
                                            ),
                                            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                                            onTap: () {
                                                // 跳到视频详情
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
}
