# Nexus AI — Project Knowledge

> **Fork of:** macai (MIT License)
> **New Name:** Nexus AI
> **Developer:** K1vin (gaoyingze)
> **Platform:** macOS (Swift/SwiftUI)
> **Project Path:** `/Users/gaoyingze/Projects/NexusAI`
> **Build Command:** `xcodebuild -project NexusAI.xcodeproj -scheme "Nexus AI" -configuration Debug CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO OTHER_CODE_SIGN_FLAGS="--entitlements macai/macai-no-icloud.entitlements" build`

---

## Available API Keys (for testing)

| Provider | Status | Vision | Image Gen |
|----------|--------|--------|-----------|
| Gemini | ✅ 付费 API | ✅ | ✅ (gemini-2.5-flash-image-preview) |
| DeepSeek | ✅ 付费 API | ❌ | ❌ |
| Claude | ✅ Max 订阅 (无 API key) | — | — |
| OpenAI | ❌ 无付费 | — | — |

---

## Current Architecture (as of fork)

### Provider System (already multi-model!)

```
Protocol: APIService (Utilities/APIHandlers/APIProtocol.swift)
├── sendMessage()           — 非流式请求
├── sendMessageStream()     — 流式请求 (AsyncThrowingStream)
├── fetchModels()           — 自动发现可用模型
└── cancelCurrentRequest()

Factory: APIServiceFactory (Utilities/APIHandlers/APIServiceFactory.swift)
├── OpenAIResponsesHandler  — OpenAI Responses API
├── ChatGPTHandler           — 通用 Chat Completions API
├── ClaudeHandler            — Anthropic API
├── GeminiHandler            — Google Gemini API (含图片生成)
├── DeepseekHandler          — DeepSeek API
├── OllamaHandler            — 本地 Ollama
├── PerplexityHandler        — Perplexity API
├── OpenRouterHandler        — OpenRouter 聚合
└── (xAI inherits ChatGPT)
```

### Key Directories
```
macai/
├── Configuration/
│   ├── AppConstants.swift          — 全局常量、Provider 默认配置
│   └── APIServiceTemplates.json    — UI 模板（Provider 显示名+模型列表）
├── Models/
│   ├── APIServiceTemplate.swift    — 模板数据模型
│   ├── ImageAttachment.swift       — 图片附件模型
│   ├── DocumentAttachment.swift    — 文档附件模型
│   └── MessageContent.swift        — 消息内容模型
├── Store/
│   ├── ChatStore.swift             — CoreData 聊天存储
│   └── macaiDataModel.xcdatamodeld — CoreData schema
├── UI/
│   ├── Chat/                       — 聊天界面（ChatView, BubbleView, Input...）
│   ├── ChatList/                   — 左侧聊天列表
│   ├── Components/                 — 通用组件
│   ├── Preferences/                — 设置页（API配置、Persona等）
│   └── WelcomeScreen/              — 欢迎页
└── Utilities/
    ├── APIHandlers/                — 各 Provider Handler
    ├── SpeechManager.swift         — TTS/STT 语音功能
    ├── ChatService.swift           — 聊天业务逻辑
    └── AttachmentParser.swift      — 附件解析
```

### Existing Features (already built)
- ✅ **多模型支持:** 9 个 Provider，含 Factory 模式 + 模板配置
- ✅ **流式输出:** 全部 Provider 支持
- ✅ **图片上传 (Vision):** Gemini, OpenAI, OpenRouter 已支持
- ✅ **图片生成:** Gemini (gemini-*-image-preview), OpenAI (DALL-E) 已支持
- ✅ **PDF 上传:** Gemini, OpenAI, OpenRouter 已支持
- ✅ **语音功能:** STT 语音输入 + TTS 朗读（SpeechManager.swift）
- ✅ **Provider logos:** Claude, Gemini, DeepSeek, Ollama, OpenAI 等全有 SVG 图标
- ✅ **Persona 系统:** 多角色预设（程序员、AI专家、健身教练等）
- ✅ **iCloud 同步:** CloudKit 可选开启
- ✅ **自动更新:** Sparkle 框架集成

### Claude Provider 当前限制
- `allowImageUploads: false` — Claude Vision API 未启用
- `imageGenerationSupported: false` — Claude 本身不支持图片生成

---

## Nexus AI 差异化开发计划（修订版）

> 原计划 7 项中，多模型切换(#1)、图片输入(#3)、图片生成(#4) 已基本完成。
> 实际需要新开发的是 macOS 原生集成功能。

### Phase 1 — macOS 原生体验（优先级最高）

| # | 功能 | 状态 | 预计工期 |
|---|------|------|----------|
| 1.1 | MenuBar 常驻 + 全局快捷键呼出 | ✅ 已完成 | — |
| 1.2 | 剪贴板监听 + 一键发送 | ✅ 已完成 | — |
| 1.3 | 本地文件拖入增强（代码/文本/PDF） | ✅ 已完成 | — |

### Phase 2 — 自动化与隐私

| # | 功能 | 状态 | 预计工期 |
|---|------|------|----------|
| 2.1 | Apple Shortcuts / App Intents 集成 | ✅ 已完成 | — |
| 2.2 | 隐私模式 UI（Ollama 强制本地） | ✅ 已完成 | — |

### Phase 3 — 补全与品牌

| # | 功能 | 状态 | 预计工期 |
|---|------|------|----------|
| 3.1 | Claude Vision API 支持启用 | ⏭️ 跳过（无 API key） | — |
| 3.2 | App 重新品牌化（名称/图标/关于页） | ✅ 已完成 | — |

**修订后总工期：15-22 天**

---

## Progress Log

### [日期] Phase 1.1 — MenuBar + 全局快捷键
- **状态：** ✅ 已完成
- **完成功能：**
  - MenuBar 图标常驻（brain.head.profile），左键呼出面板，右键菜单
  - ⌥Space 全局快捷键，任何 app 前台都可呼出
  - Quick Panel: 模型切换下拉、流式回复、自动调整窗口高度
  - Copy / New Question / Open in Main Window 按钮
  - 失焦自动关闭、Esc 关闭、面板居中屏幕顶部
- **文件清单：**
  - `UI/QuickPanel/QuickPanelWindow.swift` — NSPanel 浮动窗口
  - `UI/QuickPanel/QuickPanelController.swift` — MenuBar + 热键 + 面板管理
  - `UI/QuickPanel/QuickInputView.swift` — SwiftUI 输入/回复界面 + VisualEffectBlur
  - `macaiApp.swift` — onAppear 初始化 QuickPanelController

### [日期] Phase 1.2 — 剪贴板监听
- **状态：** ✅ 已完成
- **完成功能：**
  - ClipboardMonitor 每 0.5s 轮询 NSPasteboard，检测文本/图片/文件三种内容
  - 新内容到来时 MenuBar 图标临时闪烁为 clipboard.fill（2 秒后恢复）
  - Quick Panel 输入区新增 Clipboard 按钮（有新内容时高亮）
  - 文本内容：点击粘贴到输入框可编辑后发送
  - 图片/文件：点击自动构建分析 prompt 并发送
  - 同时修复了 SpeechManager.swift 和 VoiceInputButton.swift 不在编译列表的预存问题
- **文件清单：**
  - `Utilities/ClipboardMonitor.swift` — 剪贴板监听服务（新建）
  - `UI/QuickPanel/QuickPanelController.swift` — 新增 startClipboardMonitor + flashMenuBarIcon
  - `UI/QuickPanel/QuickInputView.swift` — 新增 clipboardButton + pasteClipboard

### [日期] Phase 1.3 — 文件拖入增强
- **状态：** ✅ 已完成
- **完成功能：**
  - Quick Panel 支持拖拽文件（蓝色边框高亮提示）
  - 支持 30+ 种文本/代码文件格式（.swift, .py, .js, .json, .md, .csv 等）
  - PDF 文件通过 PDFKit 提取文本（最多 50 页）
  - 文件内容自动截断在 15000 字符防止 prompt 过大
  - 文件附件指示条：显示文件名 + 字符数 + 删除按钮
  - 自动填充 "Please analyze this file:" 提示
  - New Question 重置时自动清除附件
- **修改文件：**
  - `UI/QuickPanel/QuickInputView.swift` — 新增 onDrop, handleFileDrop, loadFile, loadPDFText, fileIcon, buildUserMessage

---

**Phase 1 全部完成！** 接下来进入 Phase 2 — 自动化与隐私。

### [日期] Phase 2.1 — Apple Shortcuts
- **状态：** ✅ 已完成
- **完成功能：**
  - AskAIIntent — "Ask Nexus AI" 在快捷指令中提问
  - SummarizeIntent — "Summarize with AI" 摘要文本
  - TranslateIntent — "Translate with AI" 翻译文本
  - IntentAIService — 共享 AI 服务，从 CoreData 读取 API 配置
  - NexusAIShortcuts — AppShortcutsProvider 注册到系统
- **文件清单：**
  - `Intents/AskAIIntent.swift`
  - `Intents/SummarizeIntent.swift`
  - `Intents/IntentAIService.swift`
  - `Intents/NexusAIShortcuts.swift`

### [日期] Phase 2.2 — 隐私模式
- **状态：** ✅ 已完成
- **完成功能：**
  - PrivacyModeManager — 管理开关状态 + 每 10s 检测 Ollama 是否运行
  - Quick Panel 左侧 🔒 隐私开关按钮（绿色高亮 "Local"）
  - 开启后强制走 Ollama、隐藏模型选择器、跳过 API Key 检查
  - 状态持久化到 UserDefaults
- **文件清单：**
  - `Utilities/PrivacyModeManager.swift`（新建）
  - `UI/QuickPanel/QuickInputView.swift`（新增 privacyToggle + effectiveProvider 逻辑）

### [日期] Phase 3.2 — 品牌重塑
- **状态：** ✅ 已完成
- **完成内容：**
  - Info.plist: 添加 CFBundleDisplayName "Nexus AI"，所有描述文字改为 Nexus AI
  - WelcomeScreen: "Welcome to Nexus AI!"
  - nexus-ai-logo.svg: 1024x1024 app icon（紫绿渐变 + 神经网络节点）
  - README.md: 全新撰写，含功能介绍、API 设置表、原作者致谢、双版权声明
  - 许可证合规: 保留 Apache 2.0 原文 + 原始版权 + 新增 K1vin 版权

---

## 🎉 全部 Phase 完成！

**Nexus AI 差异化功能清单：**
1. ✅ MenuBar 常驻 + ⌥Space 全局快捷键
2. ✅ 剪贴板监听 + 一键分析
3. ✅ 文件拖入（30+ 格式 + PDF）
4. ✅ Apple Shortcuts（Ask AI / Summarize / Translate）
5. ✅ 隐私模式（Ollama 强制本地）
6. ✅ Quick Panel 对话同步主窗口
7. ✅ 品牌重塑（Nexus AI 名称 + Logo + README）

**GitHub 上架前 TODO：**
- [ ] 用 nexus-ai-logo.svg 生成各尺寸 PNG 图标替换 Assets.xcassets/AppIcon
- [ ] 清理 Xcode 项目中的 broken references（红色文件）
- [ ] 可选：创建新的 GitHub repo 命名为 nexus-ai
- [ ] 可选：窗口 UI 重新设计（后续版本）
