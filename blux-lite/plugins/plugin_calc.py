## blux-lite/plugins/plugin_calc.py

python
import sys

expr = " ".join(sys.argv[1:])

try:
    result = eval(expr, {"__builtins__": {}}, {})
    print("🧮 Result:", result)
except Exception as e:
    print("[!] Calculation error:", e)
