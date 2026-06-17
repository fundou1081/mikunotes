import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/providers/providers.dart';
import 'package:mikunotes/ui/screens/containers/batch_import.dart';

/// UP 主搜索页: 输入名字 → 搜 → 选 → 进入该 UP 主批量导入
class UpMasterSearchScreen extends ConsumerStatefulWidget {
  const UpMasterSearchScreen({super.key});

  @override
  ConsumerState<UpMasterSearchScreen> createState() => _UpMasterSearchScreenState();
}

class _UpMasterSearchScreenState extends ConsumerState<UpMasterSearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>>? _results;
  bool _loading = false;
  String _lastQuery = '';
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() {
        _results = null;
        _error = null;
        _loading = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () => _search(q));
  }

  Future<void> _search(String q) async {
    setState(() {
      _loading = true;
      _error = null;
      _lastQuery = q;
    });
    try {
      final bili = ref.read(bilibiliClientProvider);
      final results = await bili.searchUpMasters(q);
      if (q != _lastQuery) return; // 过时结果, 丢弃
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (e) {
      if (q != _lastQuery) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('搜索 UP 主')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '输入 UP 主名字...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 1.5)))
                    : null,
                isDense: true,
                border: const OutlineInputBorder(),
              ),
              onChanged: _onChanged,
              onSubmitted: _search,
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('搜索失败: $_error', style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: _results == null
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('输入 UP 主名字, 例如「老番茄」「影视飓风」',
                          style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
                    ),
                  )
                : _results!.isEmpty
                    ? const Center(child: Text('没找到', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: _results!.length,
                        itemBuilder: (context, index) {
                          final um = _results![index];
                          return _UpMasterResultTile(
                            um: um,
                            onTap: () => _selectUpMaster(um),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectUpMaster(Map<String, dynamic> um) async {
    final mid = um['mid'] as int;
    final name = um['name'] as String? ?? '';
    final face = um['face'] as String? ?? '';
    final r = ref;
    // 先确保 UP 主在本地 DB 里
    try {
      await r.read(databaseProvider).addOrGetUpMaster(
        uid: mid, name: name, face: face,
      );
    } catch (_) {}
    if (!mounted) return;
    // 跳到 BatchImportScreen 复用
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => BatchImportScreen(config: BatchImportConfig(
        appBarTitle: '$name (${um['fans'] ?? 0} 粉丝)',
        hintText: 'UP 主',
        resolveContainerId: () async {
          final db = r.read(databaseProvider);
          final m = await db.getUpMasterByUid(mid);
          if (m == null) throw Exception('UP 主容器未创建');
          return m.containerId;
        },
        loadPage: (page, ps) async {
          final bili = r.read(bilibiliClientProvider);
          final result = await bili.getUpMasterLatestVideos(mid, pn: page, ps: ps);
          final videos = (result['videos'] as List).map<Map<String, String>>((m) {
            final mm = m as Map;
            return {for (final e in mm.entries) e.key.toString(): e.value.toString()};
          }).toList();
          return videos;
        },
        // 不自动 sync
      )),
    ));
    // 返回后刷新 UP 主列表
    r.read(upMasterListProvider.notifier).load();
    r.read(allUpMasterVideosProvider.notifier).load();
  }
}

class _UpMasterResultTile extends StatelessWidget {
  final Map<String, dynamic> um;
  final VoidCallback onTap;
  const _UpMasterResultTile({required this.um, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = um['name'] as String? ?? '';
    final face = um['face'] as String? ?? '';
    final fans = um['fans'] as int? ?? 0;
    final sign = um['sign'] as String? ?? '';
    return ListTile(
      leading: face.isNotEmpty
          ? CircleAvatar(backgroundImage: NetworkImage(face))
          : const CircleAvatar(child: Icon(Icons.person)),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$fans 粉丝', style: const TextStyle(fontSize: 12)),
          if (sign.isNotEmpty)
            Text(sign, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
