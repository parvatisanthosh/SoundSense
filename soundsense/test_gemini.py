import requests
import json

API_KEY = 'AIzaSyA9E5q63mvxDPCVCIuaYQL3HRMudz34Knc'
URL = 'https://generativelanguage.googleapis.com/v1beta/models'

def list_models():
    try:
        response = requests.get(f"{URL}?key={API_KEY}")
        with open('models_list.txt', 'w') as f:
            if response.status_code == 200:
                models = response.json().get('models', [])
                for m in models:
                    if 'generateContent' in m['supportedGenerationMethods']:
                        f.write(f"{m['name']}\n")
            else:
                f.write(f"Error: {response.text}")
    except Exception as e:
        with open('models_list.txt', 'w') as f:
            f.write(f"Exception: {e}")

if __name__ == "__main__":
    list_models()
