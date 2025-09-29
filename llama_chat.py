from ollama import Client

client = Client()

MODEL = "codegemma"  # Change to any installed: phi3, llama3, mistral, etc.

print("🤖 BLUX AI Chat (Ctrl+C to exit)\n")

messages = []

try:
    while True:
        user_input = input("You: ").strip()
        if not user_input:
            continue

        messages.append({"role": "user", "content": user_input})
        response = client.chat(model=MODEL, messages=messages)

        assistant_msg = response['message']['content']
        messages.append({"role": "assistant", "content": assistant_msg})
        print(f"BLUX: {assistant_msg}\n")

except KeyboardInterrupt:
    print("\n[🔚 Session ended]")
