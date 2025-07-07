## docs/architecture.md

# BLUX Sovereign Lite: Architecture

## 🧠 Core Philosophy

BLUX Sovereign Lite is designed for absolute freedom and sovereignty in personal computing. It provides intelligent assistance without reliance on cloud APIs or credits. It brings intelligent terminal interaction, local file access, and code generation to any Android user with Termux.

## 📐 System Components

### 1. Termux Layer (Android)
- Provides the environment to host Linux binaries
- Initiates the install and Proot container
- Accesses local files, storage, voice, and shell

### 2. Proot Ubuntu Distro
- Creates a full Linux root filesystem inside Termux
- Separates Python/Ollama environment from Termux core
- Lightweight, containerized LLM runtime environment

### 3. Ollama Engine
- Runs `llama3:instruct` or other models entirely offline
- Provides a local REST API to interact with LLMs
- Supports additional models: CodeLLaMA, Mistral, etc.

### 4. BLUX CLI Assistant (Python)
- Terminal input loop parses command format
- `search:` = Web scraping via `ddgr`
- `read:` = File analysis (text, code, markdown, etc.)
- Default = AI prompt sent to Ollama REST endpoint

## 🔄 Interaction Flow


User → Termux → Ubuntu → Python → Ollama (LLM)
                                 ↓
                     Optional → ddgr / Local Files
                                 ↓
                             Response to User


## 🛠 Extensibility

- Plug-in architecture (`./plugins/`)
- SQLite/JSON memory persistence
- Voice mode (Termux API)
- Diagnostics, background agents

## 🔐 No Cloud, No Keys, No Credits

BLUX Sovereign Lite is built for developers, creators, minimalists, and privacy-first users. It can run without ever touching the internet after installation.

> The future is local, and you hold the power.


