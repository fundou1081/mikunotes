import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/providers/providers.dart';

/// UP主完整列表页 — 点击 UP主 Tab 顶部按钮进入
/// 支持搜索 + 列表选择, 解决 chip 太多横向滚动问题
class UpMasterListPage extends ConsumerStatefulWidget {
  final int? selectedId;
  const UpMasterListPage({super.key, this.selectedId});

  @override
  ConsumerState<UpMasterListPage> createState() => _UpMasterListPageState();
}

class _UpMasterListPageState extends ConsumerState<UpMasterListPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(upMasterListProvider);
    final all = state.maybeWhen(data: (l) => l, orElse: () => <UpMasterInfo>[]);

    // 过滤: 全部 / 搜索
    final filtered = _query.isEmpty
        ? all
        : all.where((u) => u.name.toLowerCase().contains(_query.toLowerCase())).toList();

    // "全部" 项放在最前
    final totalImported = all.fold<int>(0, (a, b) => a + b.importedCount);

    return Scaffold(
      appBar: AppBar(
        title: Text('选择 UP 主 (${all.length})'),
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
                hintText: '搜索 UP 主名字',
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
              itemCount: filtered.length + 1, // +1 for "全部" 行
              itemBuilder: (ctx, i) {
                if (i == 0) {
                  return _buildRow(
                    avatar: null,
                    name: '全部',
                    subtitle: '已导入 $totalImported 个视频',
                    isSelected: widget.selectedId == null,
                    onTap: () => Navigator.pop(ctx, null),
                  );
                }
                final um = filtered[i - 1];
                return _buildRow(
                  avatar: um.face,
                  name: um.name,
                  subtitle: '已导入 ${um.importedCount} 个',
                  isSelected: widget.selectedId == um.id,
                  onTap: () => Navigator.pop(ctx, um.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow({
    required String? avatar,
    required String name,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: avatar != null && avatar.isNotEmpty
          ? CircleAvatar(backgroundImage: NetworkImage(avatar), radius: 18)
          : const CircleAvatar(child: Icon(Icons.all_inclusive)),
      title: Text(name),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
          : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
