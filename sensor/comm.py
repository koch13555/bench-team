import network
import time
import urequests as requests  # HTTP通信用モジュール
from machine import Pin

# ==========================================
# 1. 各種設定（環境に合わせて書き換えてください）
# ==========================================
WIFI_SSID = "OIT-AirLAN.1x"
WIFI_PASSWORD = "DSKsci79&$"

# Firebase Realtime DatabaseのURL（末尾に「/変更したいパス.json」をつけます）
FIREBASE_URL = "https://【あなたのプロジェクトID】.firebaseio.com/button_events.json"

# ==========================================
# 2. Wi-Fi接続処理
# ==========================================
def connect_wifi():
    wlan = network.WLAN(network.STA_IF)
    wlan.active(True)
    if not wlan.isconnected():
        print("Wi-Fiに接続中...")
        wlan.connect(WIFI_SSID, WIFI_PASSWORD)
        
        # 接続できるまで待機（タイムアウトは15秒）
        timeout = 15
        while not wlan.isconnected() and timeout > 0:
            time.sleep(1)
            timeout -= 1
            
    if wlan.isconnected():
        print("Wi-Fi接続成功! IPアドレス:", wlan.ifconfig()[0])
    else:
        print("Wi-Fi接続失敗。設定を確認してください。")

# 起動時にWi-Fiへ接続
connect_wifi()

# ==========================================
# 3. メイン処理
# ==========================================
switch = Pin(4, Pin.IN, Pin.PULL_UP)   # GPIO4 を入力、内部プルアップON

# 前回のスイッチの状態を記憶（初期値は 1: 離されている状態）
last_state = 1

print("プログラムを開始します。スイッチを押してください。")

while True:
    current_state = switch.value()
    
    # 【条件】前回「1（離）」で、今回「0（押）」になった瞬間だけ実行
    if current_state == 0 and last_state == 1:
        print("PRESSED - Firebaseへ送信中...")
        
        # Firebaseに送信するデータ（JSON形式に自動変換されます）
        payload = {
            "status": "PRESSED",
            "device": "ESP32",
            "unixtime": time.time()  # ESP32起動からの経過秒数（簡易タイマー）
        }
        
        try:
            # FirebaseへPOSTリクエスト（データを追加保存）
            # もし常に最新の1件だけに上書きしたい場合は、.post ではなく .put に変更してください
            response = requests.post(FIREBASE_URL, json=payload)
            
            print("送信完了! ステータスコード:", response.status_code)
            print("レスポンス:", response.text)
            
            # メモリリーク（パンク）防止のため、必ずcloseする
            response.close()
            
        except Exception as e:
            print("Firebaseへの送信に失敗しました:", e)
            
    elif current_state == 1 and last_state == 0:
        # 押された状態から離されたとき
        print("RELEASED")
        
    # 現在の状態を保存して、0.1秒待つ（チャタリング防止）
    last_state = current_state
    time.sleep(0.1)