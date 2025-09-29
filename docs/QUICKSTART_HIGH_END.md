# Quick Start — Mobile High-End (Android / 12 GB+)

**Best for:** flagship Android phones (Termux), 12 GB RAM or more.  
**Goal:** run large 7B–14B models and keep multiple in storage.

## 1) Install Termux & BLUX-Lite
```bash
chmod +x ./blux-lite_installer.sh
./blux-lite_installer.sh
```

## 2) Engines & Models
```python
blux catalog download mistral7b qwen2_5_coder_7b
```

## 3) Usage
```python
blux coding --model qwen2_5_coder_7b "build a CLI for todo management"
```

# Tips

Keep at least 8–10 GB free for large models.

Use fast UFS storage for model files.


---