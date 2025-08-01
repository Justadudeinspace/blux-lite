import os
from ollama import Client

client = Client()
MODEL = "codegemma"

def create(prompt):
    messages = [{"role": "user", "content": prompt}]
    response = client.chat(model=MODEL, messages=messages)
    return {"content": response['message']['content']}

# Example usage
if __name__ == "__main__":
    user_prompt = input("Prompt: ")
    result = create(user_prompt)
    print("Response:", result["content"])
