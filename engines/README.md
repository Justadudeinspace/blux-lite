### Quickstart

### Quickstart

**First run (initial setup):**
```bash
cd blux-lite
chmod +x first_start.sh
./first_start.sh
```
This script will:
- set permissions
- install/verify dependencies
- prepare config folders
- **generate `auto-start.sh`**

**After first run (normal use):**
```bash
./auto-start.sh
```
This launches `blux-lite.sh` (Legacy/TUI menu).

# Engines

This project supports several **free, local inference engines** that can run the models in **`catalog_full.json`**, including both open-weight and API-style models:

| Engine            | Strengths & Use Case                                                  |
|-------------------|-----------------------------------------------------------------------|
| **llama.cpp**     | Efficient GGUF model loading; CPU + GPU friendly; no dependencies     |
| **Ollama**        | Simple CLI and local OpenAI-style API server                         |
| **vLLM**          | High-throughput LLM serving with OpenAI-compatible API                |
| **SGLang**        | Rust-based high-performance multi-prefix streaming                    |
| **NVIDIA Dynamo** | Scalable multi-GPU distributed serving (supports vLLM, SGLang, TRT)   |
| **AMD Gaia**      | ONNX-based local LLM app optimized for Windows (Ryzen AI support)     |
| **WebLLM**        | Runs LLM inference directly in the browser (WebGPU / WebAssembly)     |
| **OpenVINO**      | Optimized Intel inference on CPU/ARM across platforms                 |

---

## Install & Run

### llama.cpp (GGUF models)

**Linux / Termux / macOS / WSL2 / native Windows build:**
```bash
# Linux
sudo apt update && sudo apt install -y git build-essential cmake
git clone https://https://https://https://github.com/Justadudeinspace/blux-lite.cpp
cd llama.cpp && mkdir build && cd build
cmake .. && make -j$(nproc)

# macOS
xcode-select --install
git clone https://https://https://https://github.com/Justadudeinspace/blux-lite.cpp
cd llama.cpp && mkdir build && cd build
cmake .. && make -j$(sysctl -n hw.ncpu)

# WSL2 or MSYS2
# same as Linux

# Termux (Android)
pkg install git cmake clang make -y
termux-setup-storage
git clone https://https://https://https://github.com/Justadudeinspace/blux-lite.cpp
cd llama.cpp && mkdir build && cd build
cmake .. && make -j$(nproc)

Run:

./llama-cli -m ./models/your-model.gguf
llama-server -m ./models/another.gguf --port 8080
```

---

### Ollama

```bash
# Linux:
curl -fsSL https://ollama.com/install.sh | sh

## macOS & Windows:
Download the installer directly from: https://ollama.com/download

# Windows (WSL2):
Use Linux instructions inside WSL2.

# Termux (Android):
pkg update && pkg install ollama -y
ollama serve &
ollama run mistral
```

##### Run examples:
```bash
ollama pull mistral:latest
ollama run mistral

Import a local GGUF:

cat > Modelfile << 'EOF'
FROM ./vicuna-33b.Q4_0.gguf
EOF

ollama create my-vicuna -f Modelfile
ollama run my-vicuna
```

---

### vLLM (production-grade local serving)

```bash
pip install vllm

Run:

vllm serve --model-path /path/to/model
```

---

### SGLang

```bash
# Rust-based LLM server optimized for prefix reuse and streaming.

git clone https://https://https://https://github.com/Justadudeinspace/blux-lite
cd sglang && cargo build --release
./target/release/sglang-server --model model.gguf
```

---

### NVIDIA Dynamo (multi-GPU serving)

```bash
Supports vLLM, SGLang, TensorRT-LLM for distributed inference.

# Install from NVIDIA GitHub repo
```

---

### AMD Gaia (local Windows inference)

```bash
ONNX-based runtime, includes installers optimized for Ryzen AI.

# Download and run installer from AMD Gaia GitHub
```

---

### WebLLM (in-browser inference)

```bash
Runs entirely in browser via WebGPU/WebAssembly. Great for demos.

<script src="https://unpkg.com/@mlc-ai/web-llm"></script>
```

---

### Intel OpenVINO

```bash
Optimized inference for Intel hardware.

# Download from https://www.intel.com/openvino
# Example
pip install openvino
```

---

# Supported models per engine

See catalog_full.json for models mapped to engines (GGUF for llama.cpp, Ollama pulls, API endpoints for vLLM/SGLang/etc.).


---

# Catalog

A machine-readable engines catalog is provided at engines/engines_catalog.json with homepage, license, install hints, and example commands for each engine.

---

---

## ✅ Release Status

This build of **BLUX Lite GOLD v1.0.0** has passed all automated AI-based validation:
- Full Python syntax checks
- Shell script hardening and execution scans
- Dry-run and static analysis reports

It is now **open for human testing**.

👉 Please report any errors, feedback, or comments through the Issues section of this repository.

⚠️ Note: I have worked on this project independently for over 8 months, and you may occasionally encounter errors that were missed. Please report them so they can be addressed.

---