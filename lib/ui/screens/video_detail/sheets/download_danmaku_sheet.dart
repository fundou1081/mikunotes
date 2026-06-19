import 'package:flutter/material.dart';

/// 弹幕下载配置
class DanmakuDownloadConfig {
  final int maxCount;
  final int minLength; // 短内容阈值
  final bool filterShort;
  final bool filterDigits;
  final bool filterDuplicate;

  const DanmakuDownloadConfig({
    required this.maxCount,
    this.minLength = 2,
    this.filterShort = false,
    this.filterDigits = false,
    this.filterDuplicate = false,
  });
}

/// 弹幕下载配置 Sheet
class DownloadDanmakuSheet extends StatefulWidget {
  const DownloadDanmakuSheet({super.key});

  @override
  State<DownloadDanmakuSheet> createState() => _DownloadDanmakuSheetState();
}

class _DownloadDanmakuSheetState extends State<DownloadDanmakuSheet> {
  int _maxCount = 200;
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
            const Text('下载弹幕',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text(
                'B 站弹幕手动下载, 按 (bvid, page) 分P 存\n格式: <d p="time,type,...">内容</d>',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            const Text('下载数量', style: TextStyle(fontWeight: FontWeight.bold)),
            Slider(
              value: _maxCount.toDouble(),
              min: 50,
              max: 1000,
              divisions: 19,
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
              title: const Text('过滤纯数字/标点'),
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
                        DanmakuDownloadConfig(
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