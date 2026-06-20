import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/models/subtitle.dart';
import 'package:mikunotes/core/providers/providers.dart';
import 'package:mikunotes/core/storage/database.dart' as db;
import 'package:mikunotes/core/storage/database.dart' show Comment, DanmakuData;
import 'package:mikunotes/ui/screens/video_detail/widgets/shared_data.dart' show DataSource;

class RawDataTab extends ConsumerStatefulWidget {
  final String bvid;
  final VideoSubtitle? subtitle;
  final int selectedPage;
  final List<db.Subtitle> allSubtitles;
  final String? selectedLang;
  final bool loading;
  final Function(String) onLanguageChanged;
  final VoidCallback onRefresh;

  const RawDataTab({
    super.key,
    required this.bvid,
    required this.subtitle,
    required this.selectedPage,
    required this.allSubtitles,
    required this.selectedLang,
    required this.loading,
    required this.onLanguageChanged,
    required this.onRefresh,
  });

  @override
  ConsumerState<RawDataTab> createState() => RawDataTabState();
}

class RawDataTabState extends ConsumerState<RawDataTab> {
  DataSource _selectedSource = DataSource.subtitle;  // ⭐ 单选, 默认字幕
  List<db.Comment> _comments = [];
  List<DanmakuData> _danmaku = [];
  String? _activeSubLang;  // 当前显示的字幕语言
  // 字幕+弹幕 合并视图用
  @override
  void initState() {
    super.initState();
    _activeSubLang = widget.selectedLang;
    _loadComments();
    _loadDanmaku();
  }

  @override
  void didUpdateWidget(RawDataTab old) {
    super.didUpdateWidget(old);
    if (widget.selectedLang != old.selectedLang) {
      _activeSubLang = widget.selectedLang;
      }
    if (widget.selectedPage != old.selectedPage) {
      _loadComments();
      _loadDanmaku();
      }
  }

  int get _page => widget.selectedPage == 0 ? 1 : widget.selectedPage;

  Future<void> _loadComments() async {
    final dbLocal = ref.read(databaseProvider);
    _comments = await dbLocal.getCommentsForVideo(widget.bvid, page: _page);
    if (mounted) setState(() {});
  }

  Future<void> _loadDanmaku() async {
    final dbLocal = ref.read(databaseProvider);
    _danmaku = await dbLocal.getDanmakuForVideo(widget.bvid, page: _page);
    if (mounted) setState(() {});
  }

  String _fmtTime(int ms) {
    final s = ms ~/ 1000;
    final m = s ~/ 60;
    return '${m.toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 顶部: 单选 chip (字幕 / 评论 / 弹幕)
        Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              const Text('查看:', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: DataSource.values.map((s) {
                    // 判断是否可点
                    final available = switch (s) {
                      DataSource.subtitle => widget.allSubtitles.isNotEmpty,
                      DataSource.comment => _comments.isNotEmpty,
                      DataSource.danmaku => _danmaku.isNotEmpty,
                    };
                    return ChoiceChip(
                      label: Text(s.label, style: const TextStyle(fontSize: 12)),
                      selected: _selectedSource == s,
                      onSelected: available ? (_) {
                        setState(() => _selectedSource = s);
                      } : null,
                      backgroundColor: available ? null : Colors.grey.shade200,
                      tooltip: available ? null : '${s.label} 未下载',
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        // 字幕语言选择
        if (_selectedSource == DataSource.subtitle && widget.allSubtitles.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                const Text('字幕语言:', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 8),
                Expanded(
                  child: Wrap(
                    spacing: 4,
                    children: widget.allSubtitles
                        .where((s) => s.page == _page)
                        .map((s) => ChoiceChip(
                              label: Text(s.language, style: const TextStyle(fontSize: 11)),
                              selected: _activeSubLang == s.language,
                              onSelected: (_) => widget.onLanguageChanged(s.language),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        const Divider(height: 1),
        // 内容区
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildContent() {
    final parts = <Widget>[];

    switch (_selectedSource) {
      case DataSource.subtitle:
        if (widget.subtitle != null) {
          parts.add(_buildSubtitleSection());
        }
      case DataSource.comment:
        parts.add(_buildCommentSection());
      case DataSource.danmaku:
        parts.add(_buildDanmakuSection());
    }

    return ListView(
      padding: const EdgeInsets.all(0),
      children: parts,
    );
  }

  Widget _buildSubtitleSection() {
    final sub = widget.subtitle;
    if (sub == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('暂无字幕, 请先在 AppBar 菜单下载'),
      );
    }
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: const Text('📄 字幕 (完整)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: SelectableText(
            sub.fullText,
            style: const TextStyle(fontSize: 13, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildDanmakuSection() {
    if (_danmaku.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('暂无弹幕, 请先在 AppBar 菜单下载'),
      );
    }
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Text('💬 弹幕 (${_danmaku.length} 条)',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        for (final d in _danmaku.take(200))
          ListTile(
            leading: SizedBox(
              width: 56,
              child: Text(
                _fmtTime(d.progress),
                style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'monospace'),
              ),
            ),
            title: Text(d.content, maxLines: 1, overflow: TextOverflow.ellipsis),
            dense: true,
          ),
        if (_danmaku.length > 200)
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text('... 仅显示前 200 条',
                style: TextStyle(fontSize: 11, color: Colors.grey)),
          ),
      ],
    );
  }

  Widget _buildCommentSection() {
    if (_comments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('暂无评论, 请先在 AppBar 菜单下载'),
      );
    }
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Text('💭 评论 (${_comments.length} 条)',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        for (final c in _comments.take(100))
          ListTile(
            leading: CircleAvatar(
              radius: 14,
              child: Text(c.uname.isNotEmpty ? c.uname[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 12)),
            ),
            title: Text(c.content, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text('${c.uname} · 👍 ${c.likes}', style: const TextStyle(fontSize: 11)),
            isThreeLine: true,
            dense: true,
          ),
        if (_comments.length > 100)
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text('... 仅显示前 100 条',
                style: TextStyle(fontSize: 11, color: Colors.grey)),
          ),
      ],
    );
  }
}

class _AlignedSegment {
  final int start;
  final int end;
  final String text;
  final List<DanmakuData> danmaku;
  _AlignedSegment({required this.start, required this.end, required this.text, required this.danmaku});
}
