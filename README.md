

<p align="center">
  <b>"The Sovereign Termux AI Developers Assistant."</b>
</p>

# ©️ BLUX Sovereign Lite

---

<div align="center">
  
![Android](https://img.shields.io/badge/-Android-3DDC84?logo=android&logoColor=white)
![Python](https://img.shields.io/badge/-Python-3776AB?logo=python&logoColor=white)
![Termux](https://img.shields.io/badge/-Termux-000000?logo=gnu-bash&logoColor=white)
![Linux](https://img.shields.io/badge/-Linux-FCC624?logo=linux&logoColor=black)
![Open Source](https://img.shields.io/badge/-Open%20Source-0080FF?logo=github&logoColor=white)

</div>

---

## blux-sovereign-lite/

```
blux-lite/
├── README.md
├── INSTALL.md
├── LICENSE
├── blux_lite.sh
├── .blux_ubuntu_setup.sh
├── blux-lite/
│   ├── llama_chat.py
│   ├── blux_voice.py
│   ├── memory.json
│   └── plugins/
│       ├── plugin_sysinfo.py
│       └── plugin_calc.py
├── assets/
│   ├── logo.txt
│   └── banner.txt
└── docs/
    └── architecture.md
```

---

**Your fully offline, local-first AI terminal assistant for Android (Termux + Ubuntu + Ollama).**

- 🧠 Runs LLaMA 3 locally via Ollama
- 🌐 Web search via ddgr (no API, no keys)
- 📂 Reads and analyzes local files
- 🧑‍💻 Generates high-quality code offline/online
- 🔌 Plugin framework for modular intelligence
- 🗣️ Voice mode (input/output)
- 🧠 Persistent memory (JSON)
- 🧪 Self-diagnostics

---

## Quickstart

```
pkg update && pkg upgrade -y
pkg install python git curl proot-distro termux-api nano -y
pip install --upgrade pip
termux-setup-storage
git clone https://github.com/Justadudeinspace/blux-sovereign-lite.git
cd blux-sovereign-lite
chmod +x blux_lite.sh
./blux_lite.sh
```

---

## Usage

- `proot-distro login ubuntu`
- `ollama serve &`
- `python3 ~/blux-lite/llama_chat.py`

**Commands:**
- `search: <query>` — Web search
- `read: <file>` — Read local file
- `remember: <note>` — Add memory note
- `recall:` — Show memory log
- `plugin: <name> [args]` — Run plugin
- `self-check` — Diagnostics
- Anything else — LLaMA prompt

---

## Philosophy

BLUX Sovereign Lite is for creators, coders, and privacy-first users. No cloud, no keys, no credits—just pure, local AI power.

# Sponsor

<p align="center">
  <a href="https://patreon.com/Justadudeinspace">
    <img src="https://img.shields.io/badge/Sponsor%20on-Patreon-FF424D?style=for-the-badge&logo=patreon&logoColor=white" alt="Sponsor on Patreon">
  </a>
</p>

