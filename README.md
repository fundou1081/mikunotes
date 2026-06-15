# MikuNotes 🎵

> B站视频 → 你的私人知识库  
> 字幕提取 · AI 总结 · 多视频聚类 · 对话问答

[![Platform](https://img.shields.io/badge/Platform-Flutter-blue)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

## ✨ 功能

- 🔐 **B站扫码登录** — 二维码一键登录
- 📥 **字幕下载** — 自动提取 CC/AI 字幕
- 🤖 **AI 总结** — 结构化总结（概念·观点·逻辑·问答）
- 💬 **视频对话** — 基于字幕内容的 RAG 问答
- 🏷️ **主题展开** — 自定义 Prompt 深挖特定角度
- 🔗 **内容聚类** — 多视频对比分析 + 知识图谱
- 🌐 **多 AI 支持** — DeepSeek / MiniMax / 智谱 GLM / Ollama / 自定义
- 📱 **跨平台** — Android · iOS (Desktop 后续)

## 🚀 快速开始

```bash
# 1. 克隆
git clone https://github.com/fundou1081/mikunotes.git
cd mikunotes

# 2. 安装依赖
flutter pub get

# 3. 运行
flutter run
```

## 🔧 内置 AI 服务商

| 服务商 | 默认模型 | 说明 |
|--------|---------|------|
| DeepSeek | deepseek-chat | 性价比高 |
| MiniMax | MiniMax-M2.7 | 国产大模型 |
| MiniMax Free | MiniMax-M2.5-Lightning | 免费额度 |
| 智谱 GLM | glm-4-flash | 免费额度 |
| Ollama | (自选) | 本地/云端部署 |
| 自定义 | (自填) | 任意 OpenAI 兼容 |

## 🏗️ 架构

```
lib/
├── main.dart
├── core/
│   ├── models/          # 领域模型 (Video, Subtitle, Summary, Chat...)
│   ├── bilibili/        # B站 API 客户端
│   ├── llm/             # LLM 客户端 (OpenAI 兼容)
│   ├── subtitle/        # 字幕解析 (JSON → SRT → Text)
│   ├── storage/         # SQLite 数据库
│   └── providers/       # Riverpod 状态管理
└── ui/
    ├── theme/           # Material 3 主题
    ├── screens/
    │   ├── home/        # 视频列表 + 设置
    │   ├── video_detail/# 摘要 | 对话 | 字幕
    │   ├── cluster/     # 聚类图 (Phase 3)
    │   └── settings/    # AI 配置
    └── widgets/         # 通用组件
```

## 📋 开发路线

- [x] Phase 1: Python CLI (bilibili-summarizer)
- [ ] Phase 2: Flutter MVP — 登录+配置+单视频总结
- [ ] Phase 3: 多视频聚类 + 知识图谱
- [ ] Phase 4: 微信小程序 + 鸿蒙
- [ ] Phase 5: Rust 核心重写

## 📄 License

MIT
