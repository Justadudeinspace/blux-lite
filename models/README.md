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

# Models

This folder holds **local model assets** used by BLUX Lite Gold.

- **GGUF models** (for `llama.cpp`) go directly inside this folder as `.gguf` files.
- **Ollama models** are pulled into the Ollama store; they do **not** appear here as files.

## Engines & formats

- **llama.cpp** — runs `.gguf` files locally (CPU/GPU backends). `llama.cpp` requires models in **GGUF** format. 
- **Ollama** — pulls and runs models by name, e.g. `ollama run mistral`. 

## GGUF (local) models

| id | label | engine | local path / tag | source |
| --- | --- | --- | --- | --- |
| llama3-8b-instruct | Llama 3 8B Instruct (GGUF) | llama.cpp (GGUF) | models/llama-3-8b-instruct.Q4_K_M.gguf | https://huggingface.co/meta-llama/Meta-Llama-3-8B-Instruct-GGUF |
| llama3-70b-instruct | Llama 3 70B Instruct (GGUF) | llama.cpp (GGUF) | models/llama-3-70b-instruct.Q4_K_M.gguf | https://huggingface.co/meta-llama/Meta-Llama-3-70B-Instruct-GGUF |
| mistral-7b-instruct | Mistral 7B Instruct v0.2 (GGUF) | llama.cpp (GGUF) | models/mistral-7b-instruct-v0.2.Q4_K_M.gguf | https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF |
| mixtral-8x7b-instruct | Mixtral 8x7B Instruct (GGUF) | llama.cpp (GGUF) | models/mixtral-8x7b-instruct.Q4_K_M.gguf | https://huggingface.co/mistralai/Mixtral-8x7B-Instruct-v0.1 |
| gemma2-9b-it | Gemma 2 9B IT (GGUF) | llama.cpp (GGUF) | models/gemma-2-9b-it.Q4_K_M.gguf | https://huggingface.co/google/gemma-2-9b-it-GGUF |
| gemma2-2b-it | Gemma 2 2B IT (GGUF) | llama.cpp (GGUF) | models/gemma-2-2b-it.Q4_K_M.gguf | https://huggingface.co/google/gemma-2-2b-it-GGUF |
| qwen2.5-7b-instruct | Qwen2.5 7B Instruct (GGUF) | llama.cpp (GGUF) | models/qwen2.5-7b-instruct.Q4_K_M.gguf | https://huggingface.co/Qwen/Qwen2.5-7B |
| qwen2.5-3b-instruct | Qwen2.5 3B Instruct (GGUF) | llama.cpp (GGUF) | models/qwen2.5-3b-instruct.Q4_K_M.gguf | https://huggingface.co/Qwen/Qwen2.5-3B-Instruct-GGUF |
| phi-3.1-mini | Phi-3.1 Mini (GGUF) | llama.cpp (GGUF) | models/phi-3.1-mini.Q4_K_M.gguf | https://huggingface.co/microsoft/Phi-3.1-mini-GGUF |
| deepseek-coder-6.7b-instruct | DeepSeek-Coder 6.7B Instruct (GGUF) | llama.cpp (GGUF) | models/deepseek-coder-6.7b-instruct.Q4_K_M.gguf | https://huggingface.co/deepseek-ai/deepseek-coder-6.7b-instruct-GGUF |
| starcoder2-7b | StarCoder2 7B (GGUF) | llama.cpp (GGUF) | models/starcoder2-7b.Q4_K_M.gguf | https://huggingface.co/bigcode/starcoder2-7b-GGUF |
| qwen2.5-coder-7b | Qwen2.5-Coder 7B (GGUF) | llama.cpp (GGUF) | models/qwen2.5-coder-7b.Q4_K_M.gguf | https://huggingface.co/Qwen/Qwen2.5-Coder-7B-GGUF |
| code-llama-7b-instruct | Code Llama 7B Instruct (GGUF) | llama.cpp (GGUF) | models/codellama-7b-instruct.Q4_K_M.gguf | https://huggingface.co/codellama/CodeLlama-7b-Instruct-GGUF |
| tinydolphin-2.8b | TinyDolphin 2.8B (GGUF) | llama.cpp (GGUF) | models/tinydolphin-2.8b.Q4_K_M.gguf | https://huggingface.co/cognitivecomputations/TinyDolphin-2.8-GGUF |
| llama3.1-8b-instruct | Llama 3.1 8B Instruct (GGUF) | llama.cpp (GGUF) | models/llama-3.1-8b-instruct.Q4_K_M.gguf | https://huggingface.co/meta-llama/Llama-3.1-8B |
| llama3.1-70b-instruct | Llama 3.1 70B Instruct (GGUF) | llama.cpp (GGUF) | models/llama-3.1-70b-instruct.Q4_K_M.gguf | https://huggingface.co/meta-llama/Llama-3.1-70B |

> Tip: you can download GGUF files directly from Hugging Face via the `hf` CLI (provided by `huggingface_hub`):  
> `hf download <repo> --include *.gguf --local-dir ./models` 

## Ollama models

| id | label | engine | local path / tag | source |
| --- | --- | --- | --- | --- |
| llama3-8b | Llama 3 8B (Ollama) | Ollama | llama3:8b | https://ollama.com/library/llama3 |
| llama3-70b | Llama 3 70B (Ollama) | Ollama | llama3:70b | https://ollama.com/library/llama3 |
| mistral | Mistral 7B Instruct (Ollama) | Ollama | mistral:latest | https://ollama.com/library/mistral |
| mixtral | Mixtral 8x7B Instruct (Ollama) | Ollama | mixtral:8x7b | https://ollama.com/library/mixtral |
| gemma2-9b | Gemma 2 9B (Ollama) | Ollama | gemma2:9b | https://ollama.com/library/gemma2 |
| qwen2.5-7b | Qwen2.5 7B Instruct (Ollama) | Ollama | qwen2.5:7b-instruct | https://ollama.com/library/qwen2.5 |
| phi3-mini | Phi-3 Mini (Ollama) | Ollama | phi3:mini | https://ollama.com/library/phi3 |
| deepseek-coder-6.7b | DeepSeek Coder 6.7B (Ollama) | Ollama | deepseek-coder:6.7b | https://ollama.com/library/deepseek-coder |
| qwen2.5-coder-7b-ol | Qwen2.5-Coder 7B (Ollama) | Ollama | qwen2.5-coder:7b | https://ollama.com/library/qwen2.5-coder |
| starcoder2-7b-ol | StarCoder2 7B (Ollama) | Ollama | starcoder2:7b | https://ollama.com/library/starcoder2 |
| starcoder2:15b | StarCoder2 15B (Ollama) | Ollama | starcoder2:15b | https://ollama.com/library/starcoder2 |
| deepseek-coder-v2:latest | DeepSeek-Coder V2 (Ollama) | Ollama | deepseek-coder-v2:latest | https://ollama.com/library/deepseek-coder-v2 |
| codegemma:7b | CodeGemma 7B (Ollama) | Ollama | codegemma:7b | https://ollama.com/library/codegemma |
| phi3:mini | Phi-3 Mini (Ollama) | Ollama | phi3:mini | https://ollama.com/library/phi3 |

Pull a model on first use (example):
```bash
ollama pull mistral:latest
ollama run mistral
```

## Where to put things

- Place `.gguf` files **in this `models/` directory**. Update their paths in `models/catalog_full.json` if you rename them.
- Ollama models live in Ollama’s own storage; you only reference them by tag (e.g., `mixtral:8x7b`). 

## Notes on licenses

Each model has its own license and acceptable-use terms (e.g., Meta Llama, Mistral, Qwen, Gemma). Always review the model card on its source page before use.



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