# Nexus AI — Project Knowledge Base

> **GitHub:** https://github.com/K1vin1906/Nexus-AI
> **Developer:** K1vin (gaoyingze)
> **Platform:** macOS 14.0+ (Apple Silicon)
> **Language:** Swift / SwiftUI
> **License:** Apache 2.0 (forked from macai by Renat Notfullin)
> **Current Version:** 1.0.0
> **Project Path:** `/Users/gaoyingze/Projects/NexusAI`
> **Xcode Project:** `NexusAI.xcodeproj`
> **Scheme:** `Nexus AI`
> **Bundle ID:** `com.k1vin.nexusai`

---

## Build Commands

```bash
# Debug build (command line)
cd /Users/gaoyingze/Projects/NexusAI
xcodebuild -project NexusAI.xcodeproj -scheme "Nexus AI" -configuration Debug build

# Copy to Applications
cp -R ~/Library/Developer/Xcode/DerivedData/NexusAI-*/Build/Products/Debug/Nexus\ AI.app /Applications/
```

---

## Available API Keys

| Provider | Status | Chat | Vision | Image Gen |
|----------|--------|:---:|:---:|:---:|
| Gemini | ✅ 付费 | ✅ | ✅ | ✅ |
| DeepSeek | ✅ 付费 | ✅ | ❌ | ❌ |
| Claude | ❌ 仅 Max 订阅 | — | — | — |
| OpenAI | ❌ 无 | — | — | — |
| Ollama | ✅ 本地免费 | ✅ | ❌ | ❌ |

---

## Architecture Overview

```
NexusAI/
├── NexusAI.xcodeproj/
├── nexus-ai-logo.svg              — Logo 源文件 (1024x1024 SVG)
├── README.md
├── LICENSE.md                     — Apache 2.0
├── PROJECT-KNOWLEDGE.md           — 开发进度日志
└── macai/                         — 源码目录
    ├── Configuration/
    │   ├── AppConstants.swift      — 全局常量、Provider 默认配置
    │   └── APIServiceTemplates.json — Provider 模板（UI 显示名+模型列表）
    ├── Models/
    │   ├── ImageAttachment.swift
    │   ├── DocumentAttachment.swift
    │   └── MessageContent.swift
    ├── Store/
    │   ├── ChatStore.swift         — CoreData 聊天存储
    │   └── macaiDataModel.xcdatamodeld — CoreData schema (3 versions)
    ├── UI/
    │   ├── QuickPanel/             — ⭐ v1.0 新增
    │   │   ├── QuickPanelWindow.swift     — NSPanel 浮动窗口
    │   │   ├── QuickPanelController.swift — MenuBar + ⌥Space + 面板管理
    │   │   └── QuickInputView.swift       — 输入/回复/剪贴板/文件拖入/隐私模式
    │   ├── Chat/                   — 主聊天界面
    │   │   ├── ChatView.swift
    │   │   ├── ChatViewModel.swift
    │   │   ├── ChatLogicHandler.swift
    │   │   ├── ChatInputView.swift
    │   │   ├── BubbleView/
    │   │   └── BottomContainer/
    │   ├── ChatList/               — 侧边栏聊天列表
    │   ├── Components/             — 通用 UI 组件
    │   ├── Preferences/            — 设置页
    │   └── WelcomeScreen/
    ├── Intents/                    — ⭐ v1.0 新增
    │   ├── AskAIIntent.swift
    │   ├── SummarizeIntent.swift   — (含 TranslateIntent)
    │   ├── IntentAIService.swift
    │   └── NexusAIShortcuts.swift
    └── Utilities/
        ├── APIHandlers/            — 多模型 Provider 系统
        │   ├── APIProtocol.swift    — APIService protocol
        │   ├── APIServiceFactory.swift
        │   ├── ClaudeHandler.swift
        │   ├── GeminiHandler.swift
        │   ├── DeepseekHandler.swift
        │   ├── OllamaHandler.swift
        │   ├── OpenAIResponsesHandler.swift
        │   ├── OpenRouterHandler.swift
        │   └── PerplexityHandler.swift
        ├── ClipboardMonitor.swift   — ⭐ v1.0 新增
        ├── PrivacyModeManager.swift — ⭐ v1.0 新增
        ├── SpeechManager.swift      — TTS/STT 语音
        ├── ChatService.swift
        ├── TokenManager.swift       — Keychain API Key 管理
        ├── MessageManager.swift     — 消息发送/流式接收
        └── AttachmentParser.swift   — 附件解析
```

---

## Provider System (核心架构)

```
Protocol: APIService (APIProtocol.swift)
├── sendMessage()           — 非流式请求
├── sendMessageStream()     — 流式请求 (AsyncThrowingStream)
├── fetchModels()           — 自动发现可用模型
└── cancelCurrentRequest()

Factory: APIServiceFactory → 根据 config.name 创建对应 Handler
配置来源: CoreData APIServiceEntity + Keychain (TokenManager)
```

**支持的 9 个 Provider:**
openai-responses, chatgpt, claude, gemini, deepseek, ollama, perplexity, openrouter, xai

---

## v1.0 Features (已发布)

### 继承自 macai (原有功能)
- 多模型聊天 (9 providers)
- 流式响应 + Markdown 渲染 + 代码高亮 (Fira Code)
- 图片上传 Vision (Gemini, OpenAI, OpenRouter)
- 图片生成 (Gemini, OpenAI)
- PDF 上传 (Gemini, OpenAI, OpenRouter)
- AI Persona 预设系统 (8 个预设角色)
- iCloud 同步 (可选)
- 语音输入 STT + TTS 朗读
- 自动更新 (Sparkle)

### Nexus AI 新增功能
1. **MenuBar 常驻 + ⌥Space 全局快捷键** — Quick Panel 浮动面板
2. **剪贴板监听** — 检测新内容，MenuBar 图标闪烁，一键分析
3. **文件拖入** — 30+ 代码/文本格式 + PDF (PDFKit 提取)，15000 字符截断
4. **Apple Shortcuts** — Ask AI / Summarize / Translate (App Intents)
5. **隐私模式** — 🔒 按钮强制走 Ollama 本地模型
6. **Quick Panel 同步** — 对话自动保存到主窗口聊天列表 (⚡ 前缀)
7. **品牌重塑** — Nexus AI 名称/图标/README/Apache 2.0 合规

---

## v2.0 Update Plan (未来版本规划)

### 🎯 Phase A — UI 重新设计 (高优先级)

**目标：** 摆脱 macai 的原始 UI，打造专属 Nexus AI 视觉风格。

| 任务 | 描述 | 复杂度 |
|------|------|:---:|
| A1. 主题系统 | 自定义配色方案（暗色/亮色/跟随系统），Nexus 品牌色 (#6C5CE7 紫 + #4ECDC4 青) | ★★★ |
| A2. 侧边栏重设计 | 新的聊天列表样式，模型图标标识，搜索栏，固定/归档聊天 | ★★★ |
| A3. 消息气泡重设计 | 现代化气泡样式，头像/模型图标，时间戳，反应表情 | ★★★ |
| A4. 输入区重设计 | 统一的附件预览栏，拖拽区域高亮，快捷操作按钮栏 | ★★ |
| A5. Quick Panel 增强 | 多轮对话支持，历史记录，可调整面板大小 | ★★★ |
| A6. 设置页现代化 | 分组卡片式布局，Provider 配置向导，一键测试连接 | ★★ |

### 🧠 Phase B — 智能增强

| 任务 | 描述 | 复杂度 |
|------|------|:---:|
| B1. 多轮 Quick Panel | Quick Panel 支持上下文对话，不再每次单独问答 | ★★ |
| B2. 对话分支 | 从任意消息创建分支，探索不同回答方向 | ★★★★ |
| B3. 智能路由 | 根据问题类型自动选择最佳模型（代码→DeepSeek，图片→Gemini） | ★★★ |
| B4. Prompt 模板库 | 可保存/分享的 prompt 模板，一键填入 | ★★ |
| B5. RAG 本地知识库 | 索引本地文件夹，AI 基于你的文档回答问题 | ★★★★ |
| B6. 对话导出 | 导出为 Markdown / PDF / HTML | ★★ |

### 🔌 Phase C — 平台集成深化

| 任务 | 描述 | 复杂度 |
|------|------|:---:|
| C1. 系统服务集成 | 右键菜单 → "Ask Nexus AI"，全局文本选中服务 | ★★ |
| C2. Finder 扩展 | 右键文件 → "Analyze with Nexus AI" | ★★★ |
| C3. 通知中心 Widget | 显示最近对话摘要，一键 Quick Ask | ★★ |
| C4. 多窗口支持 | 独立对话窗口，可同时对比不同模型回答 | ★★ |
| C5. URL Scheme | `nexusai://ask?q=xxx` 支持从其他 app 调用 | ★ |
| C6. Automator 动作 | 扩展 Apple Shortcuts 支持更多动作 | ★★ |

### 🌍 Phase D — 新模型与能力

| 任务 | 描述 | 复杂度 |
|------|------|:---:|
| D1. Claude Vision 启用 | 当获取 Claude API key 后启用看图能力 | ★ |
| D2. 更多 Ollama 模型 | 支持 llava (本地视觉)、CodeLlama、Mistral 等 | ★ |
| D3. MCP 协议支持 | Model Context Protocol，让 AI 调用本地工具 | ★★★★ |
| D4. 联网搜索 | 集成搜索 API，AI 可查询实时信息 | ★★★ |
| D5. 代码执行 | 本地沙盒运行 AI 生成的代码 | ★★★★ |
| D6. 多模态输出 | 支持 AI 返回的音频、视频内容 | ★★★ |

### 📦 Phase E — 发布与分发

| 任务 | 描述 | 复杂度 |
|------|------|:---:|
| E1. DMG 打包 | 创建 .dmg 安装包，含拖拽安装界面 | ★★ |
| E2. Homebrew Cask | `brew install --cask nexus-ai` | ★★ |
| E3. Mac App Store | 沙盒适配 + 审核提交（需 Apple Developer 账号 $99/yr） | ★★★★ |
| E4. 自动更新迁移 | 从 Sparkle 迁移到自己的更新服务器 | ★★ |
| E5. Crash 报告 | 集成崩溃报告收集（Sentry 或自建） | ★★ |

### 📋 v2.0 Recommended Roadmap

```
v1.1 (近期):  B1 多轮 Quick Panel + B6 对话导出 + A4 输入区重设计
v1.2 (中期):  A1 主题系统 + A2 侧边栏重设计 + C1 右键菜单服务
v1.5 (中期):  B3 智能路由 + B4 Prompt 模板 + C4 多窗口
v2.0 (远期):  A 全套 UI 重设计 + B5 RAG 知识库 + D3 MCP + E1 DMG 发布
```

---

## Key Technical Notes

### API Key 存储
- 存储位置: macOS Keychain (通过 KeychainAccess 库)
- Key 格式: `api_token_{APIServiceEntity.id.uuidString}`
- 管理类: `TokenManager.swift`
- 安全: 不在任何源代码或 UserDefaults 中

### CoreData Schema
- `ChatEntity` — 聊天会话（含 requestMessages、apiService 关联）
- `MessageEntity` — 单条消息（body、own、sequence、timestamp）
- `APIServiceEntity` — API 服务配置（type、url、model、tokenIdentifier）
- `PersonaEntity` — AI 角色预设
- `ImageEntity` — 图片附件（含缩略图）
- `DocumentEntity` — 文档附件（PDF 等）
- 数据库位置: `~/Library/Application Support/macai/macaiDataModel.sqlite`

### Quick Panel 工作原理
1. `QuickPanelController` 在 app 启动时初始化 (macaiApp.swift onAppear)
2. 注册 NSStatusItem (MenuBar) + NSEvent 全局热键监听
3. ⌥Space → 创建/显示 QuickPanelWindow (NSPanel, floating)
4. QuickInputView 从 CoreData 读取 APIServiceEntity + Keychain 读取 API Key
5. 通过 APIServiceFactory 创建 Handler，调用 sendMessageStream
6. 回复完成后通过 CoreData 创建 ChatEntity + MessageEntity 同步到主窗口

### 剪贴板监听原理
- `ClipboardMonitor` 每 0.5s 轮询 NSPasteboard.general.changeCount
- 检测到变化 → 分类内容（text/image/fileURL）→ 发 Notification
- `QuickPanelController` 收到通知 → 闪烁 MenuBar 图标 2 秒
- Quick Panel 的 Clipboard 按钮检测 `hasNewContent` 状态

### 隐私模式原理
- `PrivacyModeManager` 管理开关状态 (UserDefaults)
- 每 10s 检测 Ollama 是否运行 (GET localhost:11434/api/tags)
- Quick Panel 开启隐私模式 → 强制 effectiveProvider = "ollama"
- Ollama 不需要 API Key，跳过 key 检查

### Apple Shortcuts 原理
- 使用 AppIntents framework (macOS 13+)
- 3 个 Intent struct: AskAIIntent, SummarizeIntent, TranslateIntent
- 共享 IntentAIService 单例，从 CoreData 读配置
- NexusAIShortcuts: AppShortcutsProvider 注册预置短语

---

## Development Environment

- **Machine:** Mac mini (Apple Silicon)
- **macOS User:** gaoyingze
- **Xcode:** Latest (macOS 26.4 SDK)
- **Swift:** 5
- **Deployment Target:** macOS 14.0
- **Code Signing:** Manual, sign to run locally (CODE_SIGN_IDENTITY = "-")
- **Python (Homebrew):** /opt/homebrew/bin/python3 (用于 pbxproj 操作和图标生成)
- **Key Libraries:** pbxproj (Xcode 项目管理), cairosvg (SVG→PNG)

---

## Git Remote

```
origin  → https://github.com/Renset/macai.git (原始 fork 源)
nexus   → https://github.com/K1vin1906/Nexus-AI.git (我们的 repo)
```

Push 命令: `git push nexus main`

---

*Last updated: 2026-04-03 — Nexus AI v1.0.0 发布*
