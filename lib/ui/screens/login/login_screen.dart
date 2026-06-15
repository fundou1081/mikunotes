import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/providers/providers.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// B站扫码登录
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  String? _qrcodeUrl;
  String? _qrcodeKey;
  String _status = '准备中...';
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _generateQrCode();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _generateQrCode() async {
    try {
      final bili = ref.read(bilibiliClientProvider.notifier);
      // Use the underlying client
      final client = ref.read(bilibiliClientProvider);
      final result = await client.generateQrCode();
      setState(() {
        _qrcodeUrl = result['url'];
        _qrcodeKey = result['qrcode_key'];
        _status = '请用 B站 App 扫描二维码';
      });
      _startPolling();
    } catch (e) {
      setState(() {
        _status = '生成二维码失败: $e';
      });
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_qrcodeKey == null) return;
      try {
        final client = ref.read(bilibiliClientProvider);
        final result = await client.pollQrCode(_qrcodeKey!);
        final status = result['status'] as String;
        setState(() {
          _status = switch (status) {
            'scanning' => '等待扫码...',
            'scanned' => '已扫码，请在手机上确认',
            'done' => '登录成功!',
            'timeout' => '二维码已过期，请重试',
            _ => _status,
          };
        });
        if (status == 'timeout') {
          timer.cancel();
        }
        if (status == 'done') {
          timer.cancel();
          // NOTE: 实际登录后需要从 cookie 获取 sessdata
          // 这里简化处理：用户需要手动输入 (后续会用真实 cookie 提取)
          if (mounted) {
            await _showSessdataInputDialog();
          }
        }
      } catch (_) {
        // 网络错误忽略
      }
    });
  }

  Future<void> _showSessdataInputDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('登录成功!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('请从浏览器开发者工具中复制 SESSDATA cookie：'),
            const SizedBox(height: 8),
            const Text('1. 打开 bilibili.com 并登录\n2. F12 → Application → Cookies\n3. 找到 SESSDATA 并复制其值',
                style: TextStyle(fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'SESSDATA',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              minLines: 1,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('稍后'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await ref.read(bilibiliClientProvider.notifier).setSessdata(result);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('B站扫码登录')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _qrcodeUrl == null
                    ? const SizedBox(
                        width: 200,
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : QrImageView(
                        data: _qrcodeUrl!,
                        version: QrVersions.auto,
                        size: 200,
                        backgroundColor: Colors.white,
                      ),
              ),
              const SizedBox(height: 24),
              Text(_status,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _generateQrCode,
                child: const Text('刷新二维码'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
