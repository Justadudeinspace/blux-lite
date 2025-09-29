# Quick Start — Linux (Debian/Ubuntu)

**Best for:** desktops/laptops or WSL2.  

## 1) Install BLUX-Lite
```bash
sudo apt update && sudo apt install git -y
git clone https://https://https://https://github.com/Justadudeinspace/blux-lite
cd blux-lite
chmod +x blux-lite_installer.sh
./blux-lite_installer.sh
```

## 2) Engines & Models
```python
blux catalog list
blux catalog download qwen2_5_3b mistral7b
```

## 3) Usage
```python
blux run "Summarize the Linux kernel in 3 sentences"
```

---