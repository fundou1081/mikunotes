import 'package:flutter/material.dart';

/// 评论下载配置
class CommentDownloadConfig {
  final String mode; // 'first' | 'random'
  final int maxCount;
  final int minLength; // 短内容阈值 (字符数)
  final bool filterShort;
  final bool filterDigits;
  final bool filterDuplicate;

  const CommentDownloadConfig({
    required this.mode,
    required this.maxCount,
    this.minLength = 2,
    this.filterShort = false,
    this.filterDigits = false,
    this.filterDuplicate = false,
  });
}

/// 评论下载配置 Sheet
class DownloadCommentsSheet extends StatefulWidget {
  const DownloadCommentsSheet({super.key});

  @override
  State<DownloadCommentsSheet> createState() => _DownloadCommentsSheetState();
}

class _DownloadCommentsSheetState extends State<DownloadCommentsSheet> {
  String _mode = 'first';
  int _maxCount = 100;
  int _minLength = 2;
  bool _filterShort = false;
  bool _filterDigits = true;
  bool _filterDuplicate = true;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('下载评论',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('B 站评论手动下载, 按 (bvid, page) 分P 存',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            const Text('采样方式', style: TextStyle(fontWeight: FontWeight.bold)),
            RadioListTile(
              value: 'first',
              groupValue: _mode,
              onChanged: (v) => setState(() => _mode = v!),
              title: const Text('前 N 条 (按时间/热度)'),
            ),
            RadioListTile(
              value: 'random',
              groupValue: _mode,
              onChanged: (v) => setState(() => _mode = v!),
              title: const Text('随机 N 条'),
            ),
            const SizedBox(height: 8),
            const Text('下载数量', style: TextStyle(fontWeight: FontWeight.bold)),
            Slider(
              value: _maxCount.toDouble(),
              min: 20,
              max: 500,
              divisions: 24,
              label: '$_maxCount 条',
              onChanged: (v) => setState(() => _maxCount = v.round()),
            ),
            Text('共 $_maxCount 条',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const Divider(),
            const Text('过滤选项', style: TextStyle(fontWeight: FontWeight.bold)),
            CheckboxListTile(
              value: _filterShort,
              onChanged: (v) => setState(() => _filterShort = v ?? false),
              title: const Text('过滤短内容'),
              subtitle: Slider(
                value: _minLength.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                label: '< $_minLength 字',
                onChanged: _filterShort
                    ? (v) => setState(() => _minLength = v.round())
                    : null,
              ),
              dense: true,
            ),
            CheckboxListTile(
              value: _filterDigits,
              onChanged: (v) => setState(() => _filterDigits = v ?? false),
              title: const Text('过滤纯数字/标点 (1234, ???)'),
              dense: true,
            ),
            CheckboxListTile(
              value: _filterDuplicate,
              onChanged: (v) => setState(() => _filterDuplicate = v ?? false),
              title: const Text('过滤重复 (前 20 字去重)'),
              dense: true,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        CommentDownloadConfig(
                          mode: _mode,
                          maxCount: _maxCount,
                          minLength: _minLength,
                          filterShort: _filterShort,
                          filterDigits: _filterDigits,
                          filterDuplicate: _filterDuplicate,
                        ),
                      );
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('下载'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}