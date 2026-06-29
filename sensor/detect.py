#py -m mpremote connect COM5 fs cp comm.py :comm.py
#py -m mpremote connect COM5 reset
#py -m mpremote connect COM5 repl
import network
import time
import urequests as requests
from machine import Pin

# ==========================================
# 1. 各種設定
# ==========================================
WIFI_SSID = "h/sのiPhone"
WIFI_PASSWORD = "mDj6-KA0r-Lhho-FO5a"

# 修正：seats/seat_01のパスに変更
FIREBASE_URL = "https://bench-team-app-default-rtdb.asia-southeast1.firebaseio.com/seats/seat_01.json"

# ==========================================
# 2. Wi-Fi接続処理
# ==========================================
def connect_wifi():
    wlan = network.WLAN(network.STA_IF)
    wlan.active(True)
    if not wlan.isconnected():
        print("Wi-Fiに接続中...")
        wlan.connect(WIFI_SSID, WIFI_PASSWORD)
        timeout = 15
        while not wlan.isconnected() and timeout > 0:
            time.sleep(1)
            timeout -= 1
    if wlan.isconnected():
        print("Wi-Fi接続成功! IPアドレス:", wlan.ifconfig()[0])
    else:
        print("Wi-Fi接続失敗。設定を確認してください。")

connect_wifi()

# ==========================================
# 3. メイン処理
# ==========================================
switch = Pin(4, Pin.IN, Pin.PULL_UP)
last_state = 1

print("プログラムを開始します。スイッチを押してください。")

while True:
    current_state = switch.value()
    
    if current_state == 0 and last_state == 1:
        print("PRESSED - Firebaseへ送信中...")
        
        # 修正：座席の状態を送信
        payload = {
            "occupied": True,
            "startTime": str(time.time())
        }
        
        try:
            response = requests.put(FIREBASE_URL, json=payload)
            print("送信完了! ステータスコード:", response.status_code)
            response.close()
        except Exception as e:
            print("Firebaseへの送信に失敗しました:", e)
            
    elif current_state == 1 and last_state == 0:
        print("RELEASED - 空席に戻します...")
        
        # ボタンが離されたら空席に戻す
        payload = {
            "occupied": False,
            "startTime": ""
        }
        
        try:
            response = requests.put(FIREBASE_URL, json=payload)
            print("空席に更新! ステータスコード:", response.status_code)
            response.close()
        except Exception as e:
            print("Firebaseへの送信に失敗しました:", e)
            
    last_state = current_state
    time.sleep(0.1)