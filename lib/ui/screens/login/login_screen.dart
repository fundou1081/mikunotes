import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/bilibili/bilibili_client.dart';
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
  bool _loginSuccess = false;
  BiliUser? _user;
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
    setState(() {
      _loginSuccess = false;
      _user = null;
      _status = '正在生成二维码...';
    });
    try {
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
      if (_qrcodeKey == null || _loginSuccess) return;
      try {
        final client = ref.read(bilibiliClientProvider);
        final result = await client.pollQrCode(_qrcodeKey!);
        final status = result['status'] as String;

        if (status == 'done') {
          timer.cancel();
          setState(() => _loginSuccess = true);

          final sessdata = result['sessdata'] as String?;
          final userJson = result['user'];
          BiliUser? user;
          if (userJson is Map<String, dynamic>) {
            user = BiliUser.fromJson(userJson);
          }

          if (sessdata != null && sessdata.isNotEmpty) {
            // 🎉 自动登录成功！更新状态并返回主页
            await ref
                .read(bilibiliClientProvider.notifier)
                .completeLogin(sessdata: sessdata, user: user);
            if (mounted) {
              setState(() {
                _user = user;
                _status = user != null
                    ? '✓ 登录成功，欢迎 ${user.uname}'
                    : '✓ 登录成功';
              });
              // 1.5 秒后自动返回
              Future.delayed(const Duration(milliseconds: 1500), () {
                if (mounted) Navigator.of(context).pop(true);
              });
            }
          } else {
            // B站没返回 cookie（极少见），fallback 到手动输入
            if (mounted) await _showManualSessdataDialog();
          }
        } else {
          setState(() {
            _status = switch (status) {
              'scanning' => '等待扫码...',
              'scanned' => '已扫码，请在手机上确认',
              'timeout' => '二维码已过期，请点击刷新',
              _ => _status,
            };
          });
          if (status == 'timeout') timer.cancel();
        }
      } catch (_) {
        // 网络错误忽略
      }
    });
  }

  Future<void> _showManualSessdataDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('手动输入 SESSDATA'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('自动获取失败，请在浏览器复制 SESSDATA cookie：', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            const Text('1. 打开 bilibili.com 已登录\n2. F12 → Application → Cookies\n3. 找到 SESSDATA 复制值',
                style: TextStyle(fontSize: 11)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'SESSDATA',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              minLines: 1,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      try {
        final client = ref.read(bilibiliClientProvider.notifier);
        await client.completeLogin(sessdata: result);
        try {
          final user = await ref.read(bilibiliClientProvider).fetchUserInfo();
          setState(() => _user = user);
        } catch (_) {}
        if (mounted) Navigator.of(context).pop(true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('登录失败: $e')),
          );
        }
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
                    : _loginSuccess
                        ? const Icon(Icons.check_circle, color: Colors.green, size: 80)
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
              if (_user != null) ...[
                const SizedBox(height: 12),
                Text('UID: ${_user!.mid}', style: Theme.of(context).textTheme.bodySmall),
              ],
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
