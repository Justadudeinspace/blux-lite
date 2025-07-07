## blux-lite/llama_chat.py

python
import requests, subprocess, os, json

MEMORY_FILE = os.path.expanduser("~/blux-lite/memory.json")
PLUGINS_DIR = os.path.expanduser("~/blux-lite/plugins")

if not os.path.exists(MEMORY_FILE):
    with open(MEMORY_FILE, 'w') as f:
        json.dump({"notes": []}, f)

def local_llm(prompt):
    try:
        res = requests.post("http://localhost:11434/api/generate", json={
            "model": "llama3",
            "prompt": prompt,
            "stream": False
        })
        print("\nAI:", res.json().get("response", "[No response]"))
    except Exception as e:
        print("\n[!] LLM Error:", str(e))

def search_web(query):
    try:
        result = subprocess.check_output(["ddgr", "-n", "3", query])
        print("\nWeb Search Results:\n", result.decode())
    except Exception as e:
        print("\n[!] ddgr error:", str(e))

def read_file(path):
    try:
        with open(path) as f:
            content = f.read()
        print("\nFile Preview:\n", content[:1000])
    except Exception as e:
        print("\n[!] File Error:", str(e))

def remember_note(note):
    with open(MEMORY_FILE) as f:
        mem = json.load(f)
    mem['notes'].append(note)
    with open(MEMORY_FILE, 'w') as f:
        json.dump(mem, f, indent=2)
    print("[+] Remembered.")

def recall_memory():
    with open(MEMORY_FILE) as f:
        mem = json.load(f)
    print("\n🧠 Memory:")
    for i, note in enumerate(mem['notes']):
        print(f" {i+1}. {note}")

def run_plugin(name, args):
    plugin_path = os.path.join(PLUGINS_DIR, f"{name}.py")
    if not os.path.exists(plugin_path):
        print(f"[!] Plugin '{name}' not found.")
        return
    subprocess.run(["python3", plugin_path] + args.split())

def self_check():
    print("\n🔍 Running BLUX Self-Diagnostics...")
    checks = {
        "Python": subprocess.getoutput("python --version"),
        "Pip": subprocess.getoutput("pip --version"),
        "Ollama": subprocess.getoutput("ollama --version"),
        "Model Installed": subprocess.getoutput("ollama list | grep llama3")
    }
    for k, v in checks.items():
        print(f"{k}: {v}")

print("\nBLUX Sovereign Lite is online.")

while True:
    cmd = input("\n>>> ").strip()
    if cmd.startswith("search: "):
        search_web(cmd[8:])
    elif cmd.startswith("read: "):
        read_file(cmd[6:])
    elif cmd.startswith("remember: "):
        remember_note(cmd[9:])
    elif cmd.startswith("recall"):
        recall_memory()
    elif cmd.startswith("plugin: "):
        parts = cmd[8:].split(" ", 1)
        name = parts[0]
        args = parts[1] if len(parts) > 1 else ""
        run_plugin(name, args)
    elif cmd.startswith("self-check"):
        self_check()
    else:
        local_llm(cmd)

