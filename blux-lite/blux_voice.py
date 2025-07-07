## blux-lite/blux_voice.py

python
import subprocess, time

def speak(text):
    subprocess.run(["termux-tts-speak", text])

def listen():
    try:
        out = subprocess.check_output(["termux-speech-to-text"])
        return out.decode().strip()
    except:
        return ""

print("🎙 BLUX Voice Mode — Say something...")
speak("BLUX voice assistant is ready.")

while True:
    query = listen()
    if query:
        print("You said:", query)
        speak("You said: " + query)
    else:
        print("(No input detected)")
    time.sleep(1.5)
