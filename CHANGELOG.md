# Changelog

## [0.2.0] - 2026-06-16

### Added
- **多模板系统**: 内置 8 套模板 (4 摘要 + 4 对话), 可加/编/删/设为默认
  - 摘要: 标准结构化 / 技术深度 / 教育科普 / 营销向
  - 对话: 默认助手 / 简洁版 / 深度分析 / 教学式
- **拉取可用模型**: AI 设置页点「拉取」按钮，自动调 GET /v1/models 拿列表
- **disableReasoning 参数**: 自动为 MiniMax 模型发 `chat_template_kwargs.thinking=false`
- **content fallback**: 响应 content 为空时自动 fallback 到 reasoning_content
- **后台生成**: GenerationNotifier 状态全局化，退出页面后生成继续
- **DB 驱动摘要 Tab**: 状态丢后从 SQLite 重新读取显示
- **聊天压缩**: token 超限自动压缩历史消息
- **备份/恢复**: 导入导出全部数据 (修 `Directory.toString()` bug)

### Changed
- DeepSeek 默认模型 → `deepseek-v4-flash`
- Ollama Cloud 默认 → `gemma4:31b-cloud`
- 智谱 GLM 默认 → `glm-4.6` (旧 glm-4-flash 已 404)
- 移除本地 Ollama provider (手机不需要)
- 移除 MiniMax Free 的 `api.minimaxi.com` (试通后重新加回)

### Fixed
- 摘要生成完白屏 bug (Markdown widget → SelectableText + SingleChildScrollView)
- 退出回来没生成按钮 bug (FutureBuilder + DB-driven)
- 备份导出失败 (`Directory` toString() → `dir.path`)
- 总结生成完清空状态导致重建 tab 丢失
- WBI 签名排序问题

---

## [0.1.0] - 2026-06-16

### Added
- Initial Flutter project skeleton
- 6 LLM providers: DeepSeek, MiniMax, MiniMax Free, 智谱 GLM, Ollama, Custom
- B站 API client (login/video info/subtitle)
- Subtitle parser (B站 JSON → SRT → plain text)
- Material 3 dark/light theme
- Video list + detail screen scaffold (摘要/对话/字幕 tabs)
- Settings page with AI configuration
- Riverpod state management setup
- Open-source: MIT License, GitHub ready

### TODO
- [ ] SQLite database with FTS5
- [ ] Real B站 QR code login flow (WebView)
- [ ] Subtitle download + persistence
- [ ] AI summary generation
- [ ] RAG chat per video
- [ ] Topic expansion with custom prompts
- [ ] Markdown rendering
- [ ] Cluster graph visualization (Phase 3)
- [ ] Share intent receiver (B站 links)

## [0.4.0] - 2026-06-17

### Added
- **3 平行容器架构**: 手动 / 收藏夹 / 稍后观看
  - 视频可多对多属于多个容器
  - DB schema v4: containers + container_videos 表
  - 底部 3 Tab Bar (📂 视频 / ⭐ 收藏夹 / ⏰ 稍后观看)
- **收藏夹批量导入** (Phase 2):
  - 选文件夹 → 全选未导入 / 勾选 / 搜索
  - 智能跳过已入库视频
  - 进度条 + 失败统计
- **稍后观看批量导入**: B 站 `/x/v2/history/toview` 同步
- **下载全部字幕**: 收藏夹文件夹内一键下载
  - 智能过滤已有字幕
  - 进度条 + 成功/失败 + 可中断
- **5s 撤销机制** (Phase 3):
  - 移出此收藏夹 → 5s 内可撤销 (备份 addedAt)
  - 彻底删除 → 5s 内可恢复 (备份 video + subtitles + summaries + container links)
- **新增 Future 需求 #4-A** (记下, 以后考虑): 收藏夹/稍后观看双向同步 B 站原站

### Changed
- 主页重构: HomeScreen → HomeShell (3 Tab + IndexedStack)
- 导入策略: 手动导入仍自动下字幕, 收藏夹/稍后观看**不自动下**, 用户手动下
- Container widget name collision: 全部加 `db.` 前缀

### Fixed
- 移出某容器 vs 彻底删除 语义分离 (前者不删数据, 后者全删)
- 移出后 5s 撤销保留原 addedAt 时间
- 收藏夹/稍后观看 同步时强制刷新统计
