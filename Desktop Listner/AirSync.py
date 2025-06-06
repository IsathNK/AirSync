import pyperclip
import keyboard
from time import sleep
import time
import requests

BACKEND_URL = "http://98.83.108.155:8000/api/clips"
last_clip = None


def on_hotkey():
    try: 
        print("Ctrl+C detected!")   #Hotkey Pressed
        sleep(0.1)  # Small delay to ensure clipboard is updated
        clip_text = pyperclip.paste()
        print("Current clipboard content:", clip_text)
        
        global last_clip
    
        if clip_text == last_clip:
            return  # Skip sending if it’s the same as before
        last_clip = clip_text


        payload = {
            "text": clip_text,
            "timestamp": time.time()
        }

        response = requests.post(BACKEND_URL, json=payload)
        if response.status_code == 200:
            print("Clipboard content sent successfully!")
        else:
            print("Failed to send clipboard content. Status code:", response.status_code)

        
    
    except pyperclip.PyperclipException as e:
            print("Error accessing clipboard:", e)

while True:
    keyboard.wait('ctrl+c')  # Wait for the hotkey to be pressed
    on_hotkey()  # Call the function when the hotkey is pressed
    keyboard.unhook_all_hotkeys()  # Unhook all hotkeys to avoid multiple calls
    
