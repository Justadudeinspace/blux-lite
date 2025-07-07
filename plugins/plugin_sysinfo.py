## blux-lite/plugins/plugin_sysinfo.py

python
import platform, os, subprocess

print("\n📊 System Information:")
print("OS:", platform.system(), platform.release())
print("Python:", platform.python_version())

print("\n🖥️ Termux Environment:")
print("User:", os.getenv("USER"))
print("Home:", os.getenv("HOME"))

print("\n💽 Storage:")
try:
    df = subprocess.check_output(["df", "-h", "/sdcard"]).decode()
    print(df)
except:
    print("[!] Failed to access /sdcard info")
