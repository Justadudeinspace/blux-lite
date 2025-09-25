# Quick Start — Mobile Low RAM (Android / 2–4 GB)

**Best for:** low-end Android phones with Termux, 2–4 GB RAM.  
**Goal:** run tiny local models or use APIs for quality.

## 1) Install Termux & BLUX-Lite
1. Install Termux from [F-Droid](https://f-droid.org/packages/com.termux/) (not Play Store).
2. Grant storage permissions:
```bash
termux-setup-storage
```

3. Clone and install:
```bash
pkg install git -y
git clone https://https://https://https://github.com/Justadudeinspace/blux-lite
cd blux-lite
chmod +x blux-lite_installer.sh
./blux-lite_installer.sh --simple
```


## 2) Engines & Models

API-only mode: set OPENAI_API_KEY or other compatible endpoint.

Optional tiny model:
```bash
blux catalog download tinyllama
```

## 3) Usage
```bash
blux run "Hello world"
blux coding --model tinyllama "print a random number in bash"
```

# Tips

Keep max_tokens ≤ 256.

Store .gguf in internal storage for faster load.

Use blux savscrip save to keep outputs.
