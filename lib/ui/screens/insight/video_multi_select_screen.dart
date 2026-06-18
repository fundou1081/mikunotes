import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/models/video.dart' as model;
import 'package:mikunotes/core/providers/providers.dart';

/// 多选视频 — 返回 Set<String> of BVIDs
class VideoMultiSelectScreen extends ConsumerStatefulWidget {
    final Set<String> initiallySelected;
    final String title;

    const VideoMultiSelectScreen({
        super.key,
        this.initiallySelected = const {},
        this.title = '选择视频',
    });

    @override
    ConsumerState<VideoMultiSelectScreen> createState() => _VideoMultiSelectScreenState();
}

class _VideoMultiSelectScreenState extends ConsumerState<VideoMultiSelectScreen> {
    final Set<String> _selected = {};
    List<model.Video> _videos = [];
    bool _loading = true;
    String _filter = '';

    @override
    void initState() {
        super.initState();
        _selected.addAll(widget.initiallySelected);
        _load();
    }

    Future<void> _load() async {
        setState(() => _loading = true);
        try {
            final repo = ref.read(videoRepositoryProvider);
            final all = await repo.getAllVideos();
            _videos = all;
        } finally {
            if (mounted) setState(() => _loading = false);
        }
    }

    @override
    Widget build(BuildContext context) {
        final filtered = _filter.isEmpty
            ? _videos
            : _videos.where((v) {
                final q = _filter.toLowerCase();
                return v.title.toLowerCase().contains(q) ||
                    v.bvid.toLowerCase().contains(q) ||
                    v.uploader.toLowerCase().contains(q) ||
                    v.allTags.any((t) => t.toLowerCase().contains(q));
            }).toList();

        return Scaffold(
            appBar: AppBar(
                title: Text('${widget.title} (${_selected.length})'),
                actions: [
                    IconButton(
                        icon: const Icon(Icons.check),
                        tooltip: '确定',
                        onPressed: _selected.length >= 2
                            ? () => Navigator.of(context).pop(_selected)
                            : null,
                    ),
                ],
                bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(56),
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                        child: TextField(
                            decoration: const InputDecoration(
                                hintText: '搜索标题/BV号/UP主/标签',
                                prefixIcon: Icon(Icons.search),
                                border: OutlineInputBorder(),
                                isDense: true,
                            ),
                            onChanged: (v) => setState(() => _filter = v),
                        ),
                    ),
                ),
            ),
            body: _loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                        // 提示
                        Container(
                            padding: const EdgeInsets.all(8),
                            color: Theme.of(context).colorScheme.tertiaryContainer,
                            child: Row(
                                children: [
                                    Icon(Icons.lightbulb_outline,
                                        color: Theme.of(context).colorScheme.onTertiaryContainer),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child: Text(
                                            _selected.length < 2
                                                ? '至少选 2 个视频 (已选 ${_selected.length})'
                                                : '已选 ${_selected.length} 个视频, 点 ✓ 完成',
                                            style: TextStyle(
                                                color: Theme.of(context).colorScheme.onTertiaryContainer,
                                            ),
                                        ),
                                    ),
                                ],
                            ),
                        ),
                        Expanded(
                            child: filtered.isEmpty
                                ? Center(
                                    child: Text(_videos.isEmpty
                                        ? '库中还没有视频, 请先到视频管理导入'
                                        : '没有匹配的搜索结果'),
                                )
                                : ListView.separated(
                                    itemCount: filtered.length,
                                    separatorBuilder: (_, __) => const Divider(height: 1),
                                    itemBuilder: (ctx, i) {
                                        final v = filtered[i];
                                        final selected = _selected.contains(v.bvid);
                                        return ListTile(
                                            leading: v.coverUrl.isNotEmpty
                                                ? ClipRRect(
                                                    borderRadius: BorderRadius.circular(4),
                                                    child: Image.network(
                                                        v.coverUrl,
                                                        width: 60, height: 40,
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
                                            trailing: Checkbox(
                                                value: selected,
                                                onChanged: (val) {
                                                    setState(() {
                                                        if (val == true) {
                                                            _selected.add(v.bvid);
                                                        } else {
                                                            _selected.remove(v.bvid);
                                                        }
                                                    });
                                                },
                                            ),
                                            onTap: () {
                                                setState(() {
                                                    if (selected) {
                                                        _selected.remove(v.bvid);
                                                    } else {
                                                        _selected.add(v.bvid);
                                                    }
                                                });
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
