import 'package:flutter/services.dart';

/// Android 前台服务管理器 — 通过 MethodChannel 控制原生 ForegroundService
///
/// 用途: 总结生成时保持进程存活, 切后台不中断
class ForegroundServiceManager {
  static const _channel = MethodChannel('mikunotes/bg_service');

  /// 启动前台服务 + 通知
  static Future<void> start({
    String title = 'MikuNotes',
    String text = '正在生成总结...',
  }) async {
    await _channel.invokeMethod('startService', {
      'title': title,
      'text': text,
    });
  }

  /// 更新通知文案 (流式进度)
  static Future<void> updateNotification({
    required String title,
    required String text,
  }) async {
    await _channel.invokeMethod('updateNotification', {
      'title': title,
      'text': text,
    });
  }

  /// 停止前台服务
  static Future<void> stop() async {
    await _channel.invokeMethod('stopService');
  }
}
