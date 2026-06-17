#py -m mpremote connect COM3 fs cp main.py :main.py   これでPC の main.py が ESP32 にコピーされる。
#py -m mpremote connect COM3 reset これでmain.py が自動実行される！
#py -m mpremote connect COM3 repl  出力確認
from machine import Pin
import time

switch = Pin(4, Pin.IN, Pin.PULL_UP)   # GPIO4 を入力、内部プルアップON

while True:
    if switch.value() == 0:
        print("PRESSED")
    else:
        print("RELEASED")
    time.sleep(0.1)