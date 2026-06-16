# MikuNotes 🎵

> **B 站视频学习机** — 把视频变成你的私人知识库  
> 字幕下载 · AI 总结 · 视频对话 · 多模板管理

[![Flutter](https://img.shields.io/badge/Flutter-3.41-blue)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11-0175C2)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![Version](https://img.shields.io/badge/Version-0.2.0-orange)](CHANGELOG.md)

<div align="center">
  <img src="assets/icons/app_icon_1024.png" width="120" />
</div>

## ✨ 核心功能

### 📥 B 站集成
- 二维码扫码登录（WebView）
- 自动提取 CC / AI 字幕
- 支持多 P 视频、单视频、分享链接
- WBI 签名（处理 B 站风控）

### 🤖 AI 总结
- 流式输出，**生成中可退出页面不中断**
- 多套模板（内置 8 套 + 自定义）：
  - **摘要**：标准结构化 / 技术深度 / 教育科普 / 营销向
  - **对话**：默认助手 / 简洁版 / 深度分析 / 教学式
- 模板变量：`{{video_title}} {{bvid}} {{subtitle}} {{language}} ...`
- 选中模板后再生成，可随时切换

### 💬 视频对话
- 多 Session 管理（创建 / 重命名 / 删除）
- 自动上下文压缩（超出 token 限制时）
- Token 进度条
- 基于字幕内容的 RAG 问答

### 🌐 多 AI 支持（OpenAI 兼容）

| 服务商 | 默认模型 | 特点 |
|--------|---------|------|
| **DeepSeek** | `deepseek-v4-flash` | 性价比高 |
| **MiniMax** | `MiniMax-M2.7` | 国产大模型 |
| **Ollama Cloud** | `gemma4:31b-cloud` | 免费云端 |
| **智谱 GLM** | `glm-4-flash` | 免费 flash |
| **自定义** | (自己填) | 任意 OpenAI 兼容 |

- 拉取模型列表：填好 Key 后一键拉取
- 连接测试：弹窗显示完整诊断（401/403/404 等具体错误）
- 自动 `disableReasoning`（针对 MiniMax 推理模型）

### 💾 数据管理
- **SQLite 本地存储**（drift）
- 5 张表：videos / subtitles / summaries / chat_sessions / chat_messages
- 一键备份 / 恢复（JSON 格式）
- 兼容 B 站非标准字幕 JSON（容错解析）

### 🎨 视觉
- Material 3 主题（蓝白配色）
- 自定义应用图标（音符 + 笔记本 + 渐变）
- 自适应图标（Android 8+）

---

## 🚀 快速开始

### 安装
```bash
git clone https://github.com/fundou1081/mikunotes.git
cd mikunotes
flutter pub get
dart run build_runner build   # 生成 database.g.dart
```

### 运行
```bash
# 开发模式（debug）
flutter run

# Release APK（macOS 26 需要 user 安装的 flutter）
PATH="/Users/fundou/flutter/bin:$PATH" flutter build apk --release

# Debug APK（包含完整 VM，体积大但 build 快）
flutter build apk --debug
```

### 产物
```bash
build/app/outputs/flutter-apk/app-release.apk   # ~60 MB
```

---

## 📱 部署

### Android
```bash
flutter build apk --release --target-platform android-arm64
# → 22 MB / 单 ABI
```

### 分架构打包
```bash
flutter build apk --release --split-per-abi
# → arm64-v8a.apk   (~22 MB)
# → armeabi-v7a.apk (~25 MB)
# → x86_64.apk      (~23 MB)
```

---

## 🏗️ 架构

```
lib/
├── main.dart
├── core/
│   ├── models/                # 领域模型
│   │   ├── ai_config.dart    # LLM 配置
│   │   ├── prompt_template.dart # 模板管理
│   │   ├── subtitle.dart
│   │   ├── summary.dart
│   │   └── ...
│   ├── bilibili/              # B 站 API
│   │   └── bilibili_client.dart  # WBI 签名 + 字幕
│   ├── llm/                   # LLM 客户端
│   │   ├── llm_client.dart    # OpenAI 兼容 + 流式
│   │   └── prompt_template.dart # 模板引擎
│   ├── storage/               # 数据持久化
│   │   ├── database.dart      # drift / SQLite
│   │   └── backup_service.dart
│   └── providers/             # Riverpod 状态管理
│       ├── providers.dart
│       ├── generation_provider.dart  # 后台生成（DB 驱动）
│       ├── templates_provider.dart
│       └── video_repository.dart
└── ui/
    ├── theme/
    │   └── app_theme.dart     # Material 3 主题
    └── screens/
        ├── home/              # 视频库 + 设置
        ├── login/             # B 站扫码登录
        └── video_detail/      # 三 Tab: 摘要/对话/字幕
```

### 关键技术点
- **后台生成**：`GenerationNotifier` 全局化，widget 销毁不中断
- **DB 驱动 UI**：摘要 Tab 从 SQLite 读，断网/重建状态不丢
- **WBI 签名**：处理 B 站新版 API 风控
- **dispose 安全**：所有 Riverpod provider 都有正确的生命周期管理

---

## 🛠️ 配置示例

### DeepSeek
1. 去 [platform.deepseek.com](https://platform.deepseek.com) 注册拿 API Key
2. App → 设置 → AI 配置
3. Provider: `DeepSeek`
4. Base URL: `https://api.deepseek.com`
5. API Key: `sk-xxx`
6. 模型: `deepseek-v4-flash`（默认）

### Ollama Cloud
1. 去 [ollama.com](https://ollama.com) 注册拿 API Key
2. Provider: `Ollama Cloud`
3. Base URL: `https://ollama.com/v1`
4. API Key: `7ddf...`
5. 模型: `gemma4:31b-cloud`（默认，免费层可用）

### 智谱 GLM
1. 去 [open.bigmodel.cn](https://open.bigmodel.cn) 注册拿 API Key
2. Provider: `智谱 GLM`
3. Base URL: `https://open.bigmodel.cn/api/paas/v4`
4. API Key: `xxx`
5. 模型: `glm-4-flash`（**唯一免费可用的版本**）

---

## 📋 开发路线

- [x] Phase 1: Python CLI（[bilibili-summarizer](https://github.com/fundou1081/bilibili-summarizer)）
- [x] Phase 2: Flutter MVP
  - [x] B 站登录 + 字幕下载
  - [x] AI 总结（多模板）
  - [x] 视频对话（RAG）
  - [x] 后台生成（不中断）
  - [x] 多 LLM 支持
- [ ] Phase 3: 多视频聚类图（力导向图）
- [ ] Phase 4: 微信小程序 + 鸿蒙适配
- [ ] Phase 5: Rust 核心重写

---

## 📦 相关项目

- **[bilibili-summarizer](https://github.com/fundou1081/bilibili-summarizer)** — Python CLI 原型
  - 字幕下载 + 单/批量总结 + 对比分析
  - 命令行工具，无 GUI

---

## 🤝 贡献

欢迎 PR / Issue。

---

## 📄 License

MIT