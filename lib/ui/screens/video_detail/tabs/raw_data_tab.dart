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
  Set<DataSource> _selectedSources = {DataSource.subtitle};  // 默认只看字幕
  List<db.Comment> _comments = [];
  List<DanmakuData> _danmaku = [];
  String? _activeSubLang;  // 当前显示的字幕语言
  // 字幕+弹幕 合并视图用
  List<_SrtCue> _srtCues = [];

  @override
  void initState() {
    super.initState();
    _activeSubLang = widget.selectedLang;
    _loadComments();
    _loadDanmaku();
    _loadSrtCues();
  }

  @override
  void didUpdateWidget(RawDataTab old) {
    super.didUpdateWidget(old);
    if (widget.selectedLang != old.selectedLang) {
      _activeSubLang = widget.selectedLang;
      _loadSrtCues();
    }
    if (widget.selectedPage != old.selectedPage) {
      _loadComments();
      _loadDanmaku();
      _loadSrtCues();
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

  /// 从 SRT 解析 cues (用于对齐弹幕)
  Future<void> _loadSrtCues() async {
    if (widget.allSubtitles.isEmpty || _activeSubLang == null) {
      _srtCues = [];
      return;
    }
    final sub = widget.allSubtitles.firstWhere(
      (s) => s.language == _activeSubLang && s.page == _page,
      orElse: () => widget.allSubtitles.first,
    );
    _srtCues = _parseSrtCues(sub.rawJson);
    if (mounted) setState(() {});
  }

  /// 简单 SRT 解析 (返回 [start, end, text])
  static List<_SrtCue> _parseSrtCues(String srtText) {
    final cues = <_SrtCue>[];
    final lines = srtText.split('\n');
    int i = 0;
    while (i < lines.length) {
      // 跳过空行
      while (i < lines.length && lines[i].trim().isEmpty) i++;
      if (i >= lines.length) break;
      // 序号行
      if (RegExp(r'^\d+$').hasMatch(lines[i].trim())) i++;
      if (i >= lines.length) break;
      // 时间码行: 00:00:01,000 --> 00:00:04,500
      final m = RegExp(r'(\d+):(\d+):(\d+),(\d+)\s*-->\s*(\d+):(\d+):(\d+),(\d+)').firstMatch(lines[i]);
      if (m != null) {
        final start = int.parse(m.group(1)!) * 3600000 +
            int.parse(m.group(2)!) * 60000 +
            int.parse(m.group(3)!) * 1000 +
            int.parse(m.group(4)!);
        final end = int.parse(m.group(5)!) * 3600000 +
            int.parse(m.group(6)!) * 60000 +
            int.parse(m.group(7)!) * 1000 +
            int.parse(m.group(8)!);
        i++;
        // 文本行
        final textLines = <String>[];
        while (i < lines.length && lines[i].trim().isNotEmpty) {
          textLines.add(lines[i].trim());
          i++;
        }
        cues.add(_SrtCue(start, end, textLines.join(' ')));
      } else {
        i++;
      }
    }
    return cues;
  }

  String _fmtTime(int ms) {
    final s = ms ~/ 1000;
    final m = s ~/ 60;
    return '${m.toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  /// 把弹幕按时间戳对齐到字幕 cue
  List<_AlignedSegment> _alignDanmakuToCues() {
    if (_srtCues.isEmpty || _danmaku.isEmpty) return [];
    final aligned = <_AlignedSegment>[];
    for (final cue in _srtCues) {
      // 找在 [cue.start, cue.end] 区间内的弹幕
      final inRange = _danmaku.where((d) => d.progress >= cue.start && d.progress <= cue.end).toList();
      aligned.add(_AlignedSegment(
        start: cue.start,
        end: cue.end,
        text: cue.text,
        danmaku: inRange,
      ));
    }
    return aligned;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 顶部: 多选 chip
        Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
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
                    return FilterChip(
                    label: Text(s.label, style: const TextStyle(fontSize: 12)),
                    selected: _selectedSources.contains(s),
                    onSelected: available ? (sel) {
                      setState(() {
                        if (sel) {
                          _selectedSources.add(s);
                        } else {
                          _selectedSources.remove(s);
                        }
                      });
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
        if (_selectedSources.contains(DataSource.subtitle) && widget.allSubtitles.isNotEmpty)
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
    if (_selectedSources.isEmpty) {
      return const Center(child: Text('请至少选一个数据源'));
    }
    final parts = <Widget>[];

    // 字幕 + 弹幕 合并视图
    final wantSubDanmaku = _selectedSources.contains(DataSource.subtitle) &&
        _selectedSources.contains(DataSource.danmaku);

    if (wantSubDanmaku && _srtCues.isNotEmpty) {
      final aligned = _alignDanmakuToCues();
      parts.add(Container(
        padding: const EdgeInsets.all(8),
        color: Theme.of(context).colorScheme.tertiaryContainer.withValues(alpha: 0.3),
        child: const Text('📺 字幕 + 弹幕 (按时间戳对齐)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ));
      for (final seg in aligned) {
        parts.add(_buildAlignedSegment(seg));
      }
    } else {
      // 单独显示字幕
      if (_selectedSources.contains(DataSource.subtitle) && widget.subtitle != null) {
        parts.add(_buildSubtitleSection());
      }
      // 单独显示弹幕
      if (_selectedSources.contains(DataSource.danmaku)) {
        parts.add(_buildDanmakuSection());
      }
    }

    // 评论
    if (_selectedSources.contains(DataSource.comment)) {
      parts.add(_buildCommentSection());
    }

    return ListView(
      padding: const EdgeInsets.all(0),
      children: parts,
    );
  }

  Widget _buildAlignedSegment(_AlignedSegment seg) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${_fmtTime(seg.start)} - ${_fmtTime(seg.end)}',
                    style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.blue),
                  ),
                ),
                const SizedBox(width: 8),
                if (seg.danmaku.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${seg.danmaku.length} 条弹幕',
                      style: const TextStyle(fontSize: 10, color: Colors.orange),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(seg.text, style: const TextStyle(fontSize: 13, height: 1.4)),
            if (seg.danmaku.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: seg.danmaku.take(5).map((d) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ', style: TextStyle(color: Colors.orange.shade700)),
                        Expanded(
                          child: Text(
                            d.content,
                            style: const TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ),
                        Text(
                          _fmtTime(d.progress),
                          style: const TextStyle(fontSize: 9, color: Colors.grey, fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ),
              if (seg.danmaku.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('... 还有 ${seg.danmaku.length - 5} 条',
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ),
            ],
          ],
        ),
      ),
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

class _SrtCue {
  final int start;  // ms
  final int end;    // ms
  final String text;
  _SrtCue(this.start, this.end, this.text);
}

class _AlignedSegment {
  final int start;
  final int end;
  final String text;
  final List<DanmakuData> danmaku;
  _AlignedSegment({required this.start, required this.end, required this.text, required this.danmaku});
}
