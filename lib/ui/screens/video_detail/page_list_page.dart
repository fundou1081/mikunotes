import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/providers/providers.dart';

/// 分P 列表选择页 — 从视频详情页点击分P 按钮进入
/// 显示 P 编号 / 标题 / 时长 / 字幕状态
class PageListPage extends ConsumerStatefulWidget {
  final String bvid;
  final int? selectedPage;
  const PageListPage({super.key, required this.bvid, this.selectedPage});

  @override
  ConsumerState<PageListPage> createState() => _PageListPageState();
}

class _PageListPageState extends ConsumerState<PageListPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final group = ref.watch(videoGroupProvider(widget.bvid)).maybeWhen(
          data: (g) => g,
          orElse: () => null,
        );
    final subs = ref.watch(allSubtitlesProvider(widget.bvid)).maybeWhen(
          data: (l) => l,
          orElse: () => <SubtitleInfo>[],
        );

    if (group == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 解析 pageNames (从 group.pageNamesJson)
    final pageNames = _parsePageNames(group.pageNamesJson);
    final pageCount = group.pageCount;

    // 字幕状态: 按 page 查
    final hasSubByPage = <int, bool>{};
    for (final s in subs) {
      hasSubByPage[s.page] = true;
    }

    // 过滤: "整体" + 各 P
    final entries = <_PageEntry>[];
    entries.add(_PageEntry(
      page: 0,
      title: '整体 (所有分P)',
      durationSec: group.totalDuration,
      hasSubtitle: subs.any((s) => s.page > 0),
    ));
    for (int p = 1; p <= pageCount; p++) {
      final name = (p - 1 < pageNames.length && pageNames[p - 1].isNotEmpty)
          ? pageNames[p - 1]
          : 'P$p';
      entries.add(_PageEntry(
        page: p,
        title: name,
        durationSec: null, // 暂时没有 per-page 时长
        hasSubtitle: hasSubByPage[p] ?? false,
      ));
    }

    // 搜索过滤
    final filtered = _query.isEmpty
        ? entries
        : entries.where((e) {
            final q = _query.toLowerCase();
            return e.title.toLowerCase().contains(q) ||
                'p${e.page}'.contains(q) ||
                (e.page == 0 && '整体'.contains(q));
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('选择分P ($pageCount)'),
      ),
      body: Column(
        children: [
          // 搜索框
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, size: 20),
                hintText: '搜索分P标题或 P 号',
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          // 列表
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (ctx, i) {
                final e = filtered[i];
                final selected = widget.selectedPage == e.page;
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(e.page == 0 ? '∑' : 'P${e.page}'),
                  ),
                  title: Text(
                    e.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Row(
                    children: [
                      if (e.durationSec != null && e.durationSec! > 0) ...[
                        const Icon(Icons.schedule, size: 12, color: Colors.grey),
                        const SizedBox(width: 2),
                        Text(_formatDuration(e.durationSec!),
                            style: const TextStyle(fontSize: 11)),
                        const SizedBox(width: 8),
                      ],
                      Icon(
                        e.hasSubtitle ? Icons.subtitles : Icons.subtitles_off,
                        size: 12,
                        color: e.hasSubtitle ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 2),
                      Text(e.hasSubtitle ? '已下载' : '未下载',
                          style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                  trailing: selected
                      ? Icon(Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary)
                      : const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pop(ctx, e.page),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<String> _parsePageNames(String json) {
    try {
      final list = jsonDecode(json) as List;
      return list.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  String _formatDuration(int sec) {
    if (sec < 60) return '${sec}s';
    final m = sec ~/ 60;
    final s = sec % 60;
    if (m < 60) return s == 0 ? '${m}min' : '${m}min${s}s';
    final h = m ~/ 60;
    final mm = m % 60;
    return '${h}h${mm}min';
  }
}

class _PageEntry {
  final int page;
  final String title;
  final int? durationSec;
  final bool hasSubtitle;
  _PageEntry({
    required this.page,
    required this.title,
    required this.durationSec,
    required this.hasSubtitle,
  });
}
