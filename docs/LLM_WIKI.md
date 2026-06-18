# LLM Wiki 体系 - 需求与架构

> v0.5.0 (2026-06-18) — 实施中
> 设计原则: **旁路解耦 / 自动后台 / 显式留口 / 不影响现有**

---

## 1. 背景与目标

### 1.1 背景
用户管理几百个 B 站视频, 每个视频有:
- 元数据 (标题/封面/UP主/时长/分P)
- AI 总结 (可能多个, 不同模板)
- 用户的对话记录 (基于视频内容)
- 用户打的 tag + AI 提取的 tag

之前这些信息**散落在 DB 各个表里, 难以整体浏览, LLM 也无法直接消费**。

### 1.2 目标
构建一个 **LLM 友好的 Wiki 系统**, 把视频库内容结构化为 .md 文件, 让 LLM 像人读 Wiki 一样读取。

### 1.3 关键原则
- **旁路解耦**: Wiki 写文件 ≠ 业务功能, 不影响现有 UI 行为
- **自动后台**: 视频/总结/对话/标签 一旦变化, 自动写文件, 无需用户操作
- **tags 重点**: 显式高亮, 单独段落, 方便 LLM 立即获取
- **可视化先不做**: 先把数据存好, UI 渐进式叠加

---

## 2. 架构设计

### 2.1 总体架构 (Event Bus 解耦)

```
┌──────────────────────────────────────────────────────────────┐
│  UI 层 (不动)                                                 │
│  Home / Detail / Settings / Insight(new)                     │
└──────────────────────────┬───────────────────────────────────┘
                           │ 调用 repository
                           ▼
┌──────────────────────────────────────────────────────────────┐
│  Repository 层 (只加 1 行 emit)                                │
│  addVideo()     ──→  emit(VideoAdded(bvid))                  │
│  createSummary()──→  emit(SummaryCreated(bvid))              │
│  sendChat()     ──→  emit(ChatMessageAdded(bvid))            │
│  updateTags()   ──→  emit(TagsUpdated(bvid))                 │
└──────────────────────────┬───────────────────────────────────┘
                           │ 发布事件
                           ▼
┌──────────────────────────────────────────────────────────────┐
│  EventBus (单文件, ~50 行)                                    │
│  VideoEventBus.events: Stream<VideoEvent>                    │
└──┬─────────────┬─────────────┬───────────────────────────────┘
   │             │             │
   ▼             ▼             ▼ (未来可加)
┌─────────┐  ┌─────────┐  ┌─────────┐
│Wiki Sync│  │Cloud    │  │Notion   │
│(本迭代) │  │Sync     │  │Sync     │
│写 .md   │  │(未来)   │  │(未来)   │
└─────────┘  └─────────┘  └─────────┘
```

### 2.2 为什么用 Event Bus?

| 维度 | 直接 hook | Event Bus |
|------|----------|-----------|
| 改 repository | 5 处 hook | 5 处 emit (1 行) |
| 加新功能 (云同步) | 又改 5 处 | 加一个订阅者 |
| 删 wiki 功能 | 改 5 处 + revert | 注释掉一行 `wikiSync.start()` |
| 测试 repository | 必须 mock wiki | 不用 mock |
| 性能影响 | 同步阻塞 | 异步 fire-and-forget |

### 2.3 文件结构

```
lib/
├── core/
│   ├── events/                          ← 新增
│   │   └── video_events.dart            ← 事件总线 + 4 种事件
│   ├── wiki/                            ← 新增 (独立模块)
│   │   ├── wiki_generator.dart          ← 纯函数: 数据 → markdown
│   │   ├── wiki_storage.dart            ← 文件 I/O
│   │   └── wiki_sync.dart               ← 订阅事件总线
│   ├── providers/
│   │   ├── app_mode_provider.dart       ← 已有 (v0.5.0)
│   │   ├── video_repository.dart        ← 改: 加 4 行 emit
│   │   └── providers.dart               ← 加 3 个 provider
│   └── storage/
│       └── database.dart                ← 不动
└── ui/screens/insight/                  ← 已有 (v0.5.0)
    ├── insights_home.dart               ← 完成
    ├── wiki_viewer.dart                 ← 改: 读 .md 列表
    └── wiki_chat.dart                   ← 改: LLM chat UI
```

---

## 3. 数据格式

### 3.1 Wiki 目录结构

```
/storage/emulated/0/Android/data/com.mikunotes.mikunotes/
└── files/
    └── Documents/
        └── MikuNotes_wiki/              ← wiki 根目录
            ├── index.md                 ← 索引 (所有视频列表)
            └── videos/
                ├── BV1abc123xxx_芯片验证教程.md
                ├── BV2def456yyy_RISC-V入门.md
                └── ...
```

### 3.2 单个视频 .md 模板

```markdown
---
type: video
bvid: BV1abc123xxx
title: 芯片验证教程
uploader: 胡振波
uploaded: 2026-06-01
duration: 1832
page_count: 3
added_at: 2026-06-18T19:30:00Z
exported_at: 2026-06-18T20:00:00Z
---

# 🏷️ 标签

**手动**: #RISC-V #入门 #基础
**AI 提取**: #形式化验证 #UVM #仿真 #SystemVerilog

---

# 📝 AI 总结 (3 次)

## 2026-06-18 14:23 · 默认模板

[结构化总结内容...]

## 2026-06-18 15:01 · "技术深度版" 模板

[结构化总结内容...]

---

# 💬 对话记录 (12 条, 2 个 session)

## Session 1 · 2026-06-18 14:25

**Q**: RISC-V 跟 ARM 验证方法有什么不同?

**A**: 主要区别是...

## Session 2 · 2026-06-18 15:30

**Q**: ...

**A**: ...

---

# 📄 字幕摘要 (前 30 行)

> 完整字幕请查看 B 站原视频

| 时间 | 文本 |
|------|------|
| 0:00 | 大家好... |
| 0:05 | 今天讲... |

---

# 🔗 关联 (v0.6.0 实现)

- UP 主: [[uploader:胡振波]]
- 标签: [[tag:RISC-V]] [[tag:芯片验证]]
- 关联洞察: (v0.7.0 后才有)
```

### 3.3 index.md 模板

```markdown
# MikuNotes Wiki 索引

> 共 87 个视频 · 最后更新 2026-06-18 20:00

## 📂 视频列表 (按添加时间倒序)

### 2026-06-18
- [BV1abc123 · 芯片验证教程](videos/BV1abc123xxx_芯片验证教程.md) — 胡振波 · 30:32
- [BV2def456 · RISC-V 入门](videos/BV2def456yyy_RISC-V入门.md) — 包云岗 · 45:20

### 2026-06-17
- [BV3ghi789 · 形式化验证](videos/BV3ghi789zzz_形式化验证.md) — 某 UP · 22:15
- ...

## 🏷️ 标签分布

- #RISC-V (12 个视频)
- #芯片验证 (8 个视频)
- #AI (5 个视频)
- ...
```

---

## 4. 功能列表

### 4.1 P0 — 本次 (v0.5.0 → v0.5.1, ~5h)

| # | 功能 | 状态 |
|---|------|------|
| 1 | EventBus (video_events.dart) | ⏳ |
| 2 | WikiGenerator (数据 → markdown) | ⏳ |
| 3 | WikiStorage (文件 IO) | ⏳ |
| 4 | WikiSync (订阅 bus + debounce) | ⏳ |
| 5 | Repository hooks (4 个 emit) | ⏳ |
| 6 | WikiViewer (读 .md 列表 + 渲染) | ⏳ |
| 7 | WikiChat (简单 LLM chat UI) | ⏳ |
| 8 | 启动 WikiSync (main.dart) | ⏳ |
| 9 | 模式切换 (v0.5.0 已完成) | ✅ |
| 10 | 洞察首页 (v0.5.0 已完成) | ✅ |

### 4.2 P1 — 后续 (v0.6.0, ~2h)

- Wiki Links 解析 (`[[xxx]]` 链接)
- 跳转: 视频↔UP主↔tag 互链
- 跨视频引用: 洞察里 `[[insight:xxx]]` 跳转

### 4.3 P2 — 跨视频洞察 (v0.7.0, ~3h)

- 多选视频 → 生成跨视频分析
- 洞察保存到 wiki/insights/
- 跨视频分析 prompt: 共同主题/互补信息/观点演变/跨视频洞察/学习路径

### 4.4 P3 — 主题层 (v0.8.0, ~4h)

- 从视频总结中提取主题
- 自动生成 tag 页面
- 按 tag 聚类分组

---

## 5. API 设计

### 5.1 Event Bus

```dart
// lib/core/events/video_events.dart

abstract class VideoEvent {
    final String bvid;
    const VideoEvent(this.bvid);
}

class VideoAdded extends VideoEvent { ... }
class SummaryCreated extends VideoEvent { ... }
class ChatMessageAdded extends VideoEvent { ... }
class TagsUpdated extends VideoEvent { ... }

class VideoEventBus {
    final _controller = StreamController<VideoEvent>.broadcast();
    Stream<VideoEvent> get events => _controller.stream;
    void emit(VideoEvent e) => _controller.add(e);
}

final videoEventBusProvider = Provider<VideoEventBus>((ref) {
    return VideoEventBus();
});
```

### 5.2 Wiki Storage

```dart
// lib/core/wiki/wiki_storage.dart

class WikiStorage {
    final AppDatabase _db;
    WikiStorage(this._db);

    /// Wiki 根目录: /Android/data/.../files/Documents/MikuNotes_wiki/
    Future<String> get wikiDir async { ... }

    /// 写单个视频文件 (含目录创建)
    Future<String?> writeVideoFile(String bvid) async { ... }

    /// 写索引
    Future<void> writeIndex() async { ... }

    /// 列出所有视频 .md
    Future<List<WikiFileInfo>> listVideos() async { ... }

    /// 读取文件内容
    Future<String> readFile(String relativePath) async { ... }
}

class WikiFileInfo {
    final String bvid;
    final String title;
    final String path;          // 相对路径
    final DateTime modifiedAt;
    final int sizeBytes;
}

final wikiStorageProvider = Provider<WikiStorage>((ref) {
    return WikiStorage(ref.watch(databaseProvider));
});
```

### 5.3 Wiki Generator

```dart
// lib/core/wiki/wiki_generator.dart

class WikiGenerator {
    final AppDatabase _db;
    WikiGenerator(this._db);

    /// 生成单个视频的 .md 内容 (返回 String, 不写文件)
    Future<String> generateVideoMarkdown(String bvid) async { ... }

    /// 生成 index.md
    Future<String> generateIndexMarkdown() async { ... }
}

final wikiGeneratorProvider = Provider<WikiGenerator>((ref) {
    return WikiGenerator(ref.watch(databaseProvider));
});
```

### 5.4 Wiki Sync

```dart
// lib/core/wiki/wiki_sync.dart

class WikiSync {
    final Ref _ref;
    final Set<String> _dirtyBvids = {};
    Timer? _debounceTimer;
    StreamSubscription? _sub;

    void start() {
        _sub = _ref.read(videoEventBusProvider).events.listen(_onEvent);
    }

    void stop() {
        _sub?.cancel();
        _debounceTimer?.cancel();
    }

    void _onEvent(VideoEvent e) {
        // 1s debounce, 避免短时间多个事件触发多次写
        _dirtyBvids.add(e.bvid);
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(seconds: 1), _flush);
    }

    Future<void> _flush() async {
        final bvids = _dirtyBvids.toList();
        _dirtyBvids.clear();
        final storage = _ref.read(wikiStorageProvider);
        for (final bvid in bvids) {
            try {
                await storage.writeVideoFile(bvid);
            } catch (_) {
                // 旁路: 写失败不影响业务
            }
        }
        try {
            await storage.writeIndex();
        } catch (_) {}
    }
}

final wikiSyncProvider = Provider<WikiSync>((ref) {
    return WikiSync(ref);
});
```

---

## 6. Repository 修改

### 6.1 video_repository.dart 修改清单

| 方法 | 加在哪 | 加什么 |
|------|--------|--------|
| `addVideo()` | 末尾 return 前 | `_events.emit(VideoAdded(bvid))` |
| `createSummary()` | 末尾 return 前 | `_events.emit(SummaryCreated(bvid))` |
| `updateSummaryContent()` | 末尾 return 前 | `_events.emit(SummaryCreated(bvid))` |
| `deleteSummary()` | 末尾 return 前 | `_events.emit(SummaryCreated(bvid))` |
| `sendChatMessage()` | 末尾 return 前 | `_events.emit(ChatMessageAdded(bvid))` |
| `addUserTag()` / `removeUserTag()` | 末尾 | `_events.emit(TagsUpdated(bvid))` |
| `updateVideoTags()` (AI) | 末尾 | `_events.emit(TagsUpdated(bvid))` |

**总改动量**: 7 行 emit, 不改任何业务逻辑

### 6.2 video_repository.dart 构造函数改动

```dart
class VideoRepository {
    final AppDatabase _db;
    final VideoEventBus _events;  // ← 新增字段

    VideoRepository(this._db, this._events);  // ← 新增参数
    // ...
}
```

### 6.3 providers.dart 改动

```dart
// 之前
final videoRepositoryProvider = Provider<VideoRepository>((ref) {
    return VideoRepository(ref.watch(databaseProvider));
});

// 之后
final videoRepositoryProvider = Provider<VideoRepository>((ref) {
    return VideoRepository(
        ref.watch(databaseProvider),
        ref.watch(videoEventBusProvider),
    );
});
```

---

## 7. UI 实现

### 7.1 WikiViewer (查看原始 wiki)

**布局**:
```
┌─────────────────────────────────────┐
│ 📚 Wiki 浏览           [🔄刷新]    │
├─────────────────────────────────────┤
│ 🔍 搜索...                          │
├─────────────────────────────────────┤
│ 📄 BV1abc123 · 芯片验证教程    3KB  │
│    胡振波 · 30:32 · 2分钟前更新     │
├─────────────────────────────────────┤
│ 📄 BV2def456 · RISC-V 入门    5KB  │
│    包云岗 · 45:20 · 1小时前更新     │
├─────────────────────────────────────┤
│ ...                                 │
└─────────────────────────────────────┘
```

**点击文件**:
```
┌─────────────────────────────────────┐
│ ← BV1abc123 · 芯片验证教程          │
├─────────────────────────────────────┤
│ (markdown 渲染)                     │
│                                     │
│ # 🏷️ 标签                           │
│ **手动**: #RISC-V #入门             │
│ ...                                 │
└─────────────────────────────────────┘
```

### 7.2 WikiChat (多轮对话)

**布局**:
```
┌─────────────────────────────────────┐
│ 💬 Wiki 对话        [🗑️ 新对话]    │
├─────────────────────────────────────┤
│                                     │
│       (对话气泡列表)                 │
│                                     │
│  [用户]  RISC-V 视频讲了什么?       │
│  [AI]    主要讲了 3 个方面...       │
│                                     │
│  [用户]  ...                        │
│  [AI]    ...                        │
│                                     │
├─────────────────────────────────────┤
│ [输入框............................]│
│                          [发送]     │
└─────────────────────────────────────┘
```

**v0.5.1 范围**:
- ✅ 简单 chat UI
- ✅ 调用现有 LLM client
- ❌ 不读 wiki (v0.6.0 加)

---

## 8. 风险与回退

### 8.1 风险

| 风险 | 概率 | 缓解 |
|------|------|------|
| EventBus 漏发事件 | 中 | WikiSync 加个全量重建入口 |
| 文件 IO 失败 | 低 | try/catch + 旁路不影响业务 |
| Debounce 时间太长 | 低 | 默认 1s, 可配置 |
| 用户没注意到有 wiki | 中 | InsightsHome 给引导提示 |

### 8.2 回退

- 删 wiki 目录即可 (不影响 DB)
- 注释 `WikiSync.start()` 即可禁用
- 模块完全隔离, 可整包删除

---

## 9. 实施步骤 (本次)

1. ✅ 写需求文档 (本文件)
2. ⏳ 创建 `lib/core/events/video_events.dart`
3. ⏳ 创建 `lib/core/wiki/wiki_generator.dart`
4. ⏳ 创建 `lib/core/wiki/wiki_storage.dart`
5. ⏳ 创建 `lib/core/wiki/wiki_sync.dart`
6. ⏳ 修改 `lib/core/providers/video_repository.dart` (4 emit + 1 字段)
7. ⏳ 修改 `lib/core/providers/providers.dart` (3 provider)
8. ⏳ 修改 `lib/main.dart` 启动 WikiSync
9. ⏳ 实现 `lib/ui/screens/insight/wiki_viewer.dart`
10. ⏳ 实现 `lib/ui/screens/insight/wiki_chat.dart`
11. ⏳ `flutter analyze` + `build apk`
12. ⏳ `./scripts/release.sh minor` → v0.5.1

---

## 10. 后续路线图

```
v0.5.0 ✅ 模式切换 + 洞察首页框架
v0.5.1 ⏳ Wiki 数据自动同步 + viewer + chat (本迭代)
v0.6.0 ⏳ Wiki Links 跳转 (`[[xxx]]`)
v0.7.0 ⏳ 跨视频洞察生成
v0.8.0 ⏳ 主题层 (自动 tag 聚类)
v0.9.0 ⏳ 导出 LLM Wiki 到用户目录
```

---

**作者**: AI + user
**最后更新**: 2026-06-18 19:36
