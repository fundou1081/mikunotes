import 'package:flutter/material.dart';

/// 显示带"撤销"按钮的 SnackBar (5s)
/// 用法:
///   showUndoSnackBar(context, '已删除', onUndo: () { ... });
void showUndoSnackBar(
  BuildContext context,
  String message, {
  required VoidCallback onUndo,
  Duration duration = const Duration(seconds: 5),
}) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: duration,
      action: SnackBarAction(
        label: '撤销',
        onPressed: onUndo,
      ),
    ),
  );
}
