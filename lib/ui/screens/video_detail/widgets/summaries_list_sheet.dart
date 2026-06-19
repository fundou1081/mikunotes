import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/models/summary.dart' as summary_model;
import 'package:mikunotes/core/providers/providers.dart';

class SummariesListSheet extends ConsumerWidget {
  final String bvid;
  final Function(summary_model.Summary) onSelect;
  final Function(summary_model.Summary) onDelete;
  const SummariesListSheet({
    required this.bvid,
    required this.onSelect,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      expand: false,
      builder: (ctx, scrollController) {
        return FutureBuilder<List<summary_model.Summary>>(
          future: ref.read(videoRepositoryProvider).getAllSummaries(bvid),
          builder: (ctx, snap) {
            final items = snap.data ?? [];
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.history),
                      const SizedBox(width: 8),
                      const Text('历史总结',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text('共 ${items.length} 条',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                const Divider(height: 1),
                if (snap.connectionState == ConnectionState.waiting)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('暂无历史总结')),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final s = items[i];
                        return ListTile(
                          title: Text(
                            s.title.isEmpty ? '总结 ${i + 1}' : s.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${_typeLabel(s.type)} · ${_formatDate(s.createdAt)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          onTap: () => onSelect(s),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => onDelete(s),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  String _typeLabel(summary_model.SummaryType t) {
    switch (t) {
      case summary_model.SummaryType.structured:
        return '结构化';
      case summary_model.SummaryType.topicExpansion:
        return '主题展开';
      case summary_model.SummaryType.compare:
        return '对比';
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

