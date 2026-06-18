import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/storage/database.dart';
import 'package:mikunotes/core/providers/providers.dart' show databaseProvider;

/// 图节点类型
enum GraphNodeType { video, tag, upMaster }

/// 图节点
class GraphNode {
    final String id;        // bvid / tag 名 / upMid
    final String label;     // 显示名
    final GraphNodeType type;
    final Map<String, dynamic> meta;  // 额外信息 (封面/时长/分P数 等)
    double x = 0;
    double y = 0;

    GraphNode({
        required this.id,
        required this.label,
        required this.type,
        this.meta = const {},
    });
}

/// 图边
class GraphEdge {
    final String from;   // node id
    final String to;
    final double weight; // 边的强度 (1.0 = 正常)

    GraphEdge({required this.from, required this.to, this.weight = 1.0});
}

/// 图数据加载器
class GraphDataLoader {
    final AppDatabase _db;
    GraphDataLoader(this._db);

    /// 加载图数据
    /// - 视频节点: 来自 VideoGroups
    /// - 标签节点: 来自所有 video 的 tags + aiTags
    /// - UP 主节点: 来自 UpMasters
    /// - 边: 视频-tag, 视频-up主
    Future<({List<GraphNode> nodes, List<GraphEdge> edges})> load({
        Set<String>? tagFilter,
        Set<String>? upMasterFilter,
        int maxVideos = 100,
    }) async {
        final groups = await _db.getAllVideoGroups();
        final nodes = <GraphNode>[];
        final edges = <GraphEdge>[];
        final tagSet = <String>{};
        final upMasterSet = <String>{};

        // 1. 视频节点
        var videoCount = 0;
        for (final g in groups) {
            if (videoCount >= maxVideos) break;
            // 应用筛选
            if (upMasterFilter != null && !upMasterFilter.contains(g.uploader)) continue;

            // 解析 tags
            final manualTags = _parseTags(g.tags);
            final aiTags = _parseTags(g.aiTags);
            final allTags = {...manualTags, ...aiTags};

            // 标签筛选
            if (tagFilter != null && !allTags.any(tagFilter.contains)) continue;

            nodes.add(GraphNode(
                id: g.bvid,
                label: _truncate(g.title, 12),
                type: GraphNodeType.video,
                meta: {
                    'uploader': g.uploader,
                    'duration': g.totalDuration,
                    'pageCount': g.pageCount,
                    'cover': g.cover,
                    'tags': allTags.toList(),
                },
            ));
            videoCount++;
            tagSet.addAll(allTags);
            if (g.uploader.isNotEmpty) upMasterSet.add(g.uploader);
        }

        // 2. 标签节点
        for (final tag in tagSet) {
            if (tagFilter != null && !tagFilter.contains(tag)) continue;
            nodes.add(GraphNode(
                id: 'tag:$tag',
                label: '#$tag',
                type: GraphNodeType.tag,
            ));
        }

        // 3. UP 主节点
        for (final up in upMasterSet) {
            if (upMasterFilter != null && !upMasterFilter.contains(up)) continue;
            nodes.add(GraphNode(
                id: 'up:$up',
                label: up,
                type: GraphNodeType.upMaster,
            ));
        }

        // 4. 边
        final nodeIds = {for (final n in nodes) n.id};
        for (final n in nodes.where((n) => n.type == GraphNodeType.video)) {
            final bvid = n.id;
            final tags = (n.meta['tags'] as List?)?.cast<String>() ?? [];
            for (final tag in tags) {
                final tagId = 'tag:$tag';
                if (nodeIds.contains(tagId)) {
                    edges.add(GraphEdge(from: bvid, to: tagId, weight: 1.5));
                }
            }
            final up = n.meta['uploader'] as String?;
            if (up != null && up.isNotEmpty) {
                final upId = 'up:$up';
                if (nodeIds.contains(upId)) {
                    edges.add(GraphEdge(from: bvid, to: upId, weight: 2.0));
                }
            }
        }

        return (nodes: nodes, edges: edges);
    }

    List<String> _parseTags(String raw) {
        if (raw.isEmpty) return [];
        return raw.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
    }

    String _truncate(String s, int max) {
        if (s.length <= max) return s;
        return '${s.substring(0, max - 1)}…';
    }
}

final graphDataLoaderProvider = Provider<GraphDataLoader>((ref) {
    return GraphDataLoader(ref.watch(databaseProvider));
});

/// 标签列表 provider (用于筛选)
final allTagsProvider = FutureProvider<List<String>>((ref) async {
    final db = ref.watch(databaseProvider);
    final groups = await db.getAllVideoGroups();
    final tags = <String>{};
    for (final g in groups) {
        for (final t in g.tags.split(',')) {
            if (t.trim().isNotEmpty) tags.add(t.trim());
        }
        for (final t in g.aiTags.split(',')) {
            if (t.trim().isNotEmpty) tags.add(t.trim());
        }
    }
    return tags.toList()..sort();
});

/// UP 主列表 provider
final allUpMastersProvider = FutureProvider<List<String>>((ref) async {
    final db = ref.watch(databaseProvider);
    final groups = await db.getAllVideoGroups();
    final ups = <String>{};
    for (final g in groups) {
        if (g.uploader.isNotEmpty) ups.add(g.uploader);
    }
    return ups.toList()..sort();
});
