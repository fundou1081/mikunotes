import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphview/GraphView.dart' as gv;
import 'package:mikunotes/core/wiki/graph_data.dart';
import 'package:mikunotes/ui/screens/insight/wiki_viewer.dart' show WikiFileViewer;
import 'package:mikunotes/core/wiki/wiki_storage.dart';

/// 筛选状态
class _FilterState {
    final Set<String> tags;
    final Set<String> upMasters;
    const _FilterState({this.tags = const {}, this.upMasters = const {}});
    _FilterState copyWith({Set<String>? tags, Set<String>? upMasters}) =>
        _FilterState(
            tags: tags ?? this.tags,
            upMasters: upMasters ?? this.upMasters,
        );
}

final _filterProvider = StateProvider<_FilterState>((ref) => const _FilterState());

/// 📊 图可视化 — 视频/标签/UP主 关联图
/// 基于 Fruchterman-Reingold 力导向算法
class GraphVisualization extends ConsumerStatefulWidget {
    const GraphVisualization({super.key});

    @override
    ConsumerState<GraphVisualization> createState() => _GraphVisualizationState();
}

class _GraphVisualizationState extends ConsumerState<GraphVisualization> {
    bool _loading = true;
    List<GraphNode> _nodes = [];
    List<GraphEdge> _edges = [];
    String? _error;

    // graphview 内部数据结构
    final gv.Graph _graph = gv.Graph()..isTree = false;
    final Map<String, gv.Node> _gvNodes = {};
    final Map<String, Widget> _nodeWidgets = {};
    int _reloadKey = 0;  // 用于触发 GraphView 重新构建

    @override
    void initState() {
        super.initState();
        _loadGraph();
    }

    Future<void> _loadGraph() async {
        setState(() {
            _loading = true;
            _error = null;
        });
        try {
            final filter = ref.read(_filterProvider);
            final loader = ref.read(graphDataLoaderProvider);
            final result = await loader.load(
                tagFilter: filter.tags.isEmpty ? null : filter.tags,
                upMasterFilter: filter.upMasters.isEmpty ? null : filter.upMasters,
            );
            setState(() {
                _nodes = result.nodes;
                _edges = result.edges;
                _loading = false;
                _reloadKey++;
            });
        } catch (e) {
            setState(() {
                _error = '$e';
                _loading = false;
            });
        }
    }

    gv.Graph _buildGraph() {
        _graph.nodes.clear();
        _gvNodes.clear();

        for (final n in _nodes) {
            final widget = _buildNodeWidget(n);
            final gvNode = gv.Node.Id(n.id);
            // 存到 key (Node.Id() 创建的 node 已有 key, 这里另外存 widget)
            // graphview 1.5+ 用 builder 模式, 直接返回 widget
            _gvNodes[n.id] = gvNode;
            _graph.addNode(gvNode);
            // 同时在 map 里存 widget
            _nodeWidgets[n.id] = widget;
        }

        for (final e in _edges) {
            final from = _gvNodes[e.from];
            final to = _gvNodes[e.to];
            if (from != null && to != null) {
                _graph.addEdge(from, to);
            }
        }
        return _graph;
    }

    Widget _buildNodeWidget(GraphNode n) {
        final isVideo = n.type == GraphNodeType.video;
        final isTag = n.type == GraphNodeType.tag;
        final isUp = n.type == GraphNodeType.upMaster;
        return GestureDetector(
            onTap: () => _onNodeTap(n),
            child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                constraints: BoxConstraints(
                    maxWidth: isVideo ? 120 : 100,
                    minHeight: 28,
                ),
                decoration: BoxDecoration(
                    color: isVideo
                        ? Colors.blue.shade50
                        : (isTag ? Colors.orange.shade50 : Colors.purple.shade50),
                    border: Border.all(
                        color: isVideo
                            ? Colors.blue
                            : (isTag ? Colors.orange : Colors.purple),
                        width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(isTag ? 14 : 4),
                ),
                child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        Icon(
                            isVideo ? Icons.movie : (isTag ? Icons.label : Icons.person),
                            size: 12,
                            color: isVideo
                                ? Colors.blue
                                : (isTag ? Colors.orange : Colors.purple),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                            child: Text(
                                n.label,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: isTag ? 10 : 11,
                                    fontWeight: isUp ? FontWeight.bold : FontWeight.w500,
                                    color: isVideo
                                        ? Colors.blue.shade900
                                        : (isTag ? Colors.orange.shade900 : Colors.purple.shade900),
                                ),
                            ),
                        ),
                    ],
                ),
            ),
        );
    }

    Future<void> _onNodeTap(GraphNode n) async {
        if (n.type != GraphNodeType.video) return;  // 只对视频节点响应
        final storage = ref.read(wikiStorageProvider);
        final files = await storage.listVideos();
        final file = files.where((f) => f.bvid == n.id).firstOrNull;
        if (file == null) {
            if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('该视频暂无 Wiki 记录')),
                );
            }
            return;
        }
        if (!mounted) return;
        final content = await storage.readFile(file.path);
        if (!mounted) return;
        Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => WikiFileViewer(
                    title: '${file.bvid} · ${file.title}',
                    content: content,
                ),
            ),
        );
    }

    @override
    Widget build(BuildContext context) {
        // 监听筛选变化
        ref.listen(_filterProvider, (_, __) => _loadGraph());

        if (_loading) {
            return const Center(child: CircularProgressIndicator());
        }
        if (_error != null) {
            return Center(child: Text('加载失败: $_error'));
        }
        if (_nodes.isEmpty) {
            return _emptyState();
        }

        return Column(
            children: [
                // 顶部: 统计 + 筛选
                _buildHeader(),
                // 图例
                _buildLegend(),
                // 图
                Expanded(
                    child: Container(
                        color: const Color(0xFFF5F5F5),
                        child: InteractiveViewer(
                            constrained: false,
                            boundaryMargin: const EdgeInsets.all(1000),
                            minScale: 0.1,
                            maxScale: 4.0,
                            child: gv.GraphView(
                                key: ValueKey(_reloadKey),
                                graph: _buildGraph(),
                                algorithm: gv.FruchtermanReingoldAlgorithm(
                                    gv.FruchtermanReingoldConfiguration(
                                        iterations: 200,
                                        attractionRate: 0.15,
                                        repulsionRate: 0.2,
                                    ),
                                ),
                                paint: Paint()
                                    ..color = Colors.grey.shade400
                                    ..strokeWidth = 1
                                    ..style = PaintingStyle.stroke,
                                builder: (node) {
                                    // 从 key 找到 widget
                                    final key = node.key?.value;
                                    if (key is String && _nodeWidgets.containsKey(key)) {
                                        return _nodeWidgets[key]!;
                                    }
                                    return Container(width: 20, height: 20, color: Colors.red);
                                },
                            ),
                        ),
                    ),
                ),
            ],
        );
    }

    Widget _buildHeader() {
        return Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
                children: [
                    Icon(Icons.account_tree,
                        color: Theme.of(context).colorScheme.onPrimaryContainer),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(
                            '${_nodes.where((n) => n.type == GraphNodeType.video).length} 视频 · '
                            '${_nodes.where((n) => n.type == GraphNodeType.tag).length} 标签 · '
                            '${_nodes.where((n) => n.type == GraphNodeType.upMaster).length} UP主 · '
                            '${_edges.length} 关联',
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                        ),
                    ),
                    IconButton(
                        icon: const Icon(Icons.filter_alt, size: 18),
                        tooltip: '筛选',
                        onPressed: _showFilterSheet,
                    ),
                    IconButton(
                        icon: const Icon(Icons.refresh, size: 18),
                        tooltip: '刷新',
                        onPressed: _loadGraph,
                    ),
                ],
            ),
        );
    }

    Widget _buildLegend() {
        return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            color: Colors.grey.shade100,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    _legendItem('视频', Colors.blue, Icons.movie),
                    const SizedBox(width: 12),
                    _legendItem('标签', Colors.orange, Icons.label),
                    const SizedBox(width: 12),
                    _legendItem('UP主', Colors.purple, Icons.person),
                ],
            ),
        );
    }

    Widget _legendItem(String text, Color color, IconData icon) {
        return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
                Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        border: Border.all(color: color, width: 1.5),
                        borderRadius: BorderRadius.circular(text == '标签' ? 6 : 2),
                    ),
                ),
                const SizedBox(width: 4),
                Text(text, style: const TextStyle(fontSize: 11)),
            ],
        );
    }

    Widget _emptyState() {
        return Center(
            child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        Icon(Icons.account_tree,
                            size: 80, color: Theme.of(context).colorScheme.outline),
                        const SizedBox(height: 16),
                        Text('图谱为空', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(
                            '导入视频/打标签 后, 这里会自动生成关联图',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.outline,
                            ),
                        ),
                    ],
                ),
            ),
        );
    }

    Future<void> _showFilterSheet() async {
        final tags = await ref.read(allTagsProvider.future);
        final ups = await ref.read(allUpMastersProvider.future);
        if (!mounted) return;

        final current = ref.read(_filterProvider);
        final selectedTags = {...current.tags};
        final selectedUps = {...current.upMasters};

        await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (ctx) => StatefulBuilder(
                builder: (ctx, setStateSheet) {
                    return DraggableScrollableSheet(
                        expand: false,
                        initialChildSize: 0.7,
                        maxChildSize: 0.9,
                        builder: (_, scrollCtrl) => Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Row(
                                        children: [
                                            const Text('筛选', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                            const Spacer(),
                                            TextButton(
                                                onPressed: () {
                                                    setStateSheet(() {
                                                        selectedTags.clear();
                                                        selectedUps.clear();
                                                    });
                                                },
                                                child: const Text('清空'),
                                            ),
                                        ],
                                    ),
                                    const SizedBox(height: 8),
                                    if (tags.isNotEmpty) ...[
                                        const Text('🏷️ 标签', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Wrap(
                                            spacing: 4, runSpacing: 4,
                                            children: [
                                                for (final t in tags)
                                                    FilterChip(
                                                        label: Text('#$t', style: const TextStyle(fontSize: 12)),
                                                        selected: selectedTags.contains(t),
                                                        onSelected: (sel) {
                                                            setStateSheet(() {
                                                                if (sel) {
                                                                    selectedTags.add(t);
                                                                } else {
                                                                    selectedTags.remove(t);
                                                                }
                                                            });
                                                        },
                                                    ),
                                            ],
                                        ),
                                        const SizedBox(height: 12),
                                    ],
                                    if (ups.isNotEmpty) ...[
                                        const Text('👤 UP 主', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Wrap(
                                            spacing: 4, runSpacing: 4,
                                            children: [
                                                for (final u in ups)
                                                    FilterChip(
                                                        label: Text(u, style: const TextStyle(fontSize: 12)),
                                                        selected: selectedUps.contains(u),
                                                        onSelected: (sel) {
                                                            setStateSheet(() {
                                                                if (sel) {
                                                                    selectedUps.add(u);
                                                                } else {
                                                                    selectedUps.remove(u);
                                                                }
                                                            });
                                                        },
                                                    ),
                                            ],
                                        ),
                                    ],
                                    const Spacer(),
                                    SizedBox(
                                        width: double.infinity,
                                        child: FilledButton.icon(
                                            onPressed: () {
                                                ref.read(_filterProvider.notifier).state = _FilterState(
                                                    tags: selectedTags,
                                                    upMasters: selectedUps,
                                                );
                                                Navigator.pop(ctx);
                                            },
                                            icon: const Icon(Icons.check),
                                            label: const Text('应用'),
                                        ),
                                    ),
                                ],
                            ),
                        ),
                    );
                },
            ),
        );
    }
}

extension _FirstOrNull<T> on Iterable<T> {
    T? get firstOrNull {
        final it = iterator;
        if (it.moveNext()) return it.current;
        return null;
    }
}
