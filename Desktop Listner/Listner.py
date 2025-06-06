import pyperclip
from time import sleep

def on_hotkey():
    try: 
        print("Ctrl+C detected!")   #Hotkey Pressed
        sleep(0.1)  # Small delay to ensure clipboard is updated
        currentClipboard = pyperclip.paste()
        print("Current clipboard content:", currentClipboard)
        
    
    except pyperclip.PyperclipException as e:
            print("Error accessing clipboard:", e)
