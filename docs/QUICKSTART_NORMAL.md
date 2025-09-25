# Quick Start — Mobile Normal (Android / 6–8 GB)

**Best for:** mid-tier Android phones with Termux, 6–8 GB RAM.  
**Goal:** run 3B–7B models locally for coding & general tasks.

## 1) Install Termux & BLUX-Lite
(Same as low-RAM, but skip `--simple` to get full menu.)

```bash
chmod +x ./blux-lite_installer.sh
./blux-lite_installer.sh
```

## 2) Engines & Models
```python
blux catalog list
blux catalog download qwen2_5_3b
```

## 3) Usage
```python
blux coding --model qwen2_5_3b "write a Python script for image resize"
```

# Tips

Internal storage is faster than SD.

Use ```blux bench local``` to test model latency.


---