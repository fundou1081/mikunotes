import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 视频相关事件 - 解耦 repository 和 wiki/其他订阅者
///
/// 设计原则:
/// - Repository 不直接调用 wiki storage, 只发布事件
/// - 多个订阅者可独立订阅 (wiki 写文件/未来云同步/统计等)
/// - 订阅者 fire-and-forget, 失败不影响业务

/// 事件基类
abstract class VideoEvent {
    final String bvid;
    const VideoEvent(this.bvid);
}

/// 视频被添加到库
class VideoAdded extends VideoEvent {
    const VideoAdded(super.bvid);
}

/// 视频被删除
class VideoRemoved extends VideoEvent {
    const VideoRemoved(super.bvid);
}

/// 视频元数据更新 (封面/标题/分P/UP主等)
class VideoMetadataUpdated extends VideoEvent {
    const VideoMetadataUpdated(super.bvid);
}

/// 该视频有新的总结生成
class SummaryCreated extends VideoEvent {
    final int summaryId;
    const SummaryCreated(super.bvid, {required this.summaryId});
}

/// 总结被删除
class SummaryDeleted extends VideoEvent {
    final int summaryId;
    const SummaryDeleted(super.bvid, {required this.summaryId});
}

/// 该视频有新对话消息
class ChatMessageAdded extends VideoEvent {
    final int sessionId;
    const ChatMessageAdded(super.bvid, {required this.sessionId});
}

/// 对话被删除
class ChatSessionDeleted extends VideoEvent {
    final int sessionId;
    const ChatSessionDeleted(super.bvid, {required this.sessionId});
}

/// 该视频的标签被修改 (用户打 / AI 提取)
class TagsUpdated extends VideoEvent {
    const TagsUpdated(super.bvid);
}

/// 事件总线
class VideoEventBus {
    final _controller = StreamController<VideoEvent>.broadcast();

    /// 订阅事件流
    Stream<VideoEvent> get events => _controller.stream;

    /// 发布事件
    void emit(VideoEvent e) {
        if (!_controller.isClosed) _controller.add(e);
    }

    /// 关闭总线
    void close() {
        _controller.close();
    }
}

/// 全局 VideoEventBus provider
final videoEventBusProvider = Provider<VideoEventBus>((ref) {
    final bus = VideoEventBus();
    ref.onDispose(bus.close);
    return bus;
});
