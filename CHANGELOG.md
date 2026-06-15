# Changelog

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
