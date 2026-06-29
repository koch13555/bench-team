import network

import time

import sys

import urequests as requests  # HTTP通信用モジュール

from machine import Pin
 
# ==========================================

# 1. 各種設定（環境に合わせて書き換えてください）

# ==========================================

# ※iPhoneのテザリングを使用する場合は、事前にiPhone側で

#   「互換性を優先」をONにし、iPhoneの名前を半角英数字に変更してください。

WIFI_SSID = "bench"

WIFI_PASSWORD = "e5wzeexbgragz"
 
# Firebase Realtime DatabaseのURL

# -------------------------------------------------------------------------

# 【設定方法】

# Firebaseコンソールの「Realtime Database」画面の一番上に表示されている

# 「https://〜〜〜/」というURLをそのまま貼り付け、末尾に「button_events.json」を書き加えてください。

#

# 改良コードのURL例（お使いの環境に合わせて以下のいずれかの形になります）：

# ① "https://プロジェクトID-default-rtdb.firebaseio.com/button_events.json"

# ② "https://プロジェクトID-default-rtdb.asia-southeast1.firebasedatabase.app/button_events.json"

# -------------------------------------------------------------------------

FIREBASE_URL = "https://bench-team-app-default-rtdb.asia-southeast1.firebasedatabase.app/button_events.json"
 
# ==========================================

# 2. Wi-Fi接続処理

# ==========================================

def connect_wifi():
    wlan = network.WLAN(network.STA_IF)
    wlan.active(True)
    if not wlan.isconnected():
        print("Wi-Fiに接続中....")
        wlan.connect(WIFI_SSID, WIFI_PASSWORD)
        # 接続できるまで待機（タイムアウトは15秒）
        timeout = 15
        while not wlan.isconnected() and timeout > 0:
            time.sleep(1)
            print(timeout)
            timeout -= 1
    if wlan.isconnected():
        print("Wi-Fi接続成功! IPアドレス:", wlan.ifconfig()[0])
    else:
        print("Wi-Fi接続失敗。設定を確認してください。")
        sys.exit()  # 接続できない場合は安全のため停止します
 
# 起動時にWi-Fiへ接続

connect_wifi()
 
# ==========================================

# 3. メイン処理

# ==========================================

pir = Pin(4, Pin.IN)
 
# 状態管理用の変数

last_state = 0                     # 前回のセンサー状態（初期値は 0: 反応なし）

last_detection_time = time.time()  # 最後にセンサーが反応した時間

p10_sent = True                    # すでに 'p10' を送信済みかどうかのフラグ（起動時は送信済み扱い）
 
# センサーの起動直後は動作が不安定（常に1になる等）な場合があるため、少し待機します

print("センサーの安定化を待機中（約5秒）...")

time.sleep(5)
 
print("プログラムを開始します。人感センサーを監視中...")
 
while True:

    val = pir.value()

    current_time = time.time()

    # ターミナルに現在のセンサーの値を表示（0.5秒おき）

    print(val)

    # 【要素1】センサーが新しく反応した瞬間（前回「0」で、今回「1」になった瞬間）

    if val == 1 and last_state == 0:

        print("モーション検知! - Firebaseへ 'p11' を送信中...")

        payload = {

            "status": "p11",

            "device": "ESP32",

            "unixtime": current_time

        }

        try:

            response = requests.post(FIREBASE_URL, json=payload)

            print("送信完了! ステータスコード:", response.status_code)

            response.close()  # メモリリーク（パンク）防止

        except Exception as e:

            print("Firebaseへの送信に失敗しました:", e)

        p10_sent = False  # 新たに反応があったので、p10（未反応通知）を送れる状態に戻す
 
    # センサーが反応している（1の）間は、最終検知時間を「今」に更新し続ける

    if val == 1:

        last_detection_time = current_time

    # 【要素2】センサーに反応がなく（0）、最後に反応してから10秒以上経ち、まだ 'p10' を送っていない場合

    if val == 0 and (current_time - last_detection_time) >= 10 and not p10_sent:

        print("10秒間センサーに反応がありません。 - Firebaseへ 'p10' を送信中...")

        payload = {

            "status": "p10",

            "device": "ESP32",

            "unixtime": current_time

        }

        try:

            response = requests.post(FIREBASE_URL, json=payload)

            print("送信完了! ステータスコード:", response.status_code)

            response.close()  # メモリリーク（パンク）防止

        except Exception as e:

            print("Firebaseへの送信に失敗しました:", e)

        p10_sent = True  # 'p10' を送信したので、次の検知があるまで再送信を防ぐ
 
    # 次のループのために状態を保存し、0.5秒待つ

    last_state = val

    time.sleep(0.5)
 