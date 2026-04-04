# Nexus AI

<p align="center">
  <img src="screenshot-hero.png" alt="Nexus AI" width="100%">
</p>

A native macOS AI chat client with multi-model support, web search, MCP tools, and system-level integration.

[![Download](https://img.shields.io/badge/Download-v2.0-6C5CE7?style=for-the-badge&logo=apple&logoColor=white)](https://github.com/K1vin1906/Nexus-AI/releases/tag/v2.0)
[![License](https://img.shields.io/badge/License-Apache_2.0-4ECDC4?style=for-the-badge)](LICENSE.md)
[![macOS](https://img.shields.io/badge/macOS-14.0+-000?style=for-the-badge&logo=apple)](https://github.com/K1vin1906/Nexus-AI)

## What's New in v2.0

- **🌐 Gemini Web Search** — Real-time Google Search grounding with source citations
- **🔌 MCP Integration** — Connect AI to local tools via Model Context Protocol
- **🎨 Modern UI** — Redesigned message bubbles with provider avatars and brand colors
- **⚙️ Settings Overhaul** — Grouped card layout with provider icons and one-click test

## Features

### 9 AI Providers
Connect to multiple AI providers from a single interface:
- **Google Gemini** — chat, vision, image generation, **web search**
- **DeepSeek** — fast reasoning with thinking process display
- **Claude** (Anthropic) — advanced reasoning
- **OpenAI** — GPT models with vision and DALL-E
- **Ollama** — local models, fully offline
- **Perplexity** — built-in web search with citations
- **OpenRouter, xAI** — and more

### Smart Features
- **Smart Router** — auto-routes queries to the best model (code → DeepSeek, images → Gemini)
- **Prompt Templates** — 12 built-in templates + custom templates with category filtering
- **Multi-Window** — open chats in independent windows for side-by-side comparison
- **MCP Tools** — AI can discover and call local tools via Model Context Protocol
- **Web Search** — Gemini Google Search grounding with real-time sources

### macOS Native Experience
- **MenuBar App** — always one click away
- **Global Hotkey (⌥Space)** — Spotlight-like Quick Panel for instant AI access
- **File Drag & Drop** — drop code, text, PDFs directly into chat
- **Clipboard Monitoring** — detect new content, one-click analyze
- **Apple Shortcuts** — Ask AI, Summarize, Translate in automation workflows
- **System Services** — right-click "Ask/Summarize/Translate with Nexus AI"
- **Privacy Mode** — force all traffic through local Ollama

### Chat Features
- Streaming responses with Markdown rendering and code highlighting
- AI Personas with custom system prompts
- PDF and image attachments (Gemini, OpenAI, OpenRouter)
- Image generation (Gemini, OpenAI)
- Chat export to Markdown, PDF, and HTML
- Chat search and history with iCloud sync
- Voice input (STT) and Text-to-Speech
- NexusTheme with 7 accent colors and dark/light modes

## Installation

**Download:** Grab the [latest DMG](https://github.com/K1vin1906/Nexus-AI/releases/tag/v2.0), open it, drag Nexus AI to Applications.

**Requirements:** macOS 14.0+ (Apple Silicon)

**Build from source:**
```bash
git clone https://github.com/K1vin1906/Nexus-AI.git
cd Nexus-AI
open NexusAI.xcodeproj
# Build and run (⌘R)
```

## API Setup

| Provider | Get API Key | Free Tier? |
|----------|------------|:---:|
| Gemini | [Google AI Studio](https://aistudio.google.com/app/apikey) | ✅ |
| DeepSeek | [DeepSeek Platform](https://platform.deepseek.com/) | Limited |
| Claude | [Anthropic Console](https://console.anthropic.com/) | ❌ |
| OpenAI | [OpenAI Platform](https://platform.openai.com/) | ❌ |
| Ollama | [ollama.com](https://ollama.com/) | ✅ Local |

## Acknowledgments

Nexus AI is a derivative work based on [macai](https://github.com/Renset/macai) by **Renat Notfullin**, licensed under the Apache License 2.0.

## License

Copyright 2025 K1vin · Licensed under [Apache 2.0](LICENSE.md)
