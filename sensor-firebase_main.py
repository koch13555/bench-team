#"""
#main.py
#ESP32 (MicroPython) - 人感センサの検知結果を Firebase Realtime Database に送信する

#【全体の流れ】
#  1. Wi-Fi に接続する
#  2. 人感センサ(PIRセンサ等)のGPIOピンを監視する
#  3. 「未検知 -> 検知」に変化した瞬間に Firebase Realtime Database へ
#     HTTP PUT リクエストを送って状態を更新する

#【他メンバーのコードと組み合わせる場合】
#  人感センサの検知部分は read_motion_sensor() 関数にまとめてあります。
#  ここを、チームメンバーが書いたセンサ読み取り処理に置き換えるだけで
#  そのまま利用できます。
#  例: motion_detected = your_teammate_function()##
#"""

import network
import urequests
import time
from machine import Pin

# ============================================================
# 1. 設定値（環境に合わせて書き換えてください）
# ============================================================

# --- Wi-Fi 設定 ---
WIFI_SSID = "YOUR_WIFI_SSID"
WIFI_PASSWORD = "YOUR_WIFI_PASSWORD"

# --- Firebase Realtime Database 設定 ---
# Firebaseコンソール > プロジェクトの設定 > 一般 から確認できる
# データベースURL（末尾のスラッシュは付けない）
# 例: https://your-project-id-default-rtdb.firebaseio.com
FIREBASE_URL = "https://YOUR_PROJECT_ID-default-rtdb.firebaseio.com"

# Realtime Database内のどこにデータを書き込むかのパス（任意の名前でOK）
# 最終的なエンドポイントは FIREBASE_URL + DB_PATH + ".json" になる
DB_PATH = "/sensors/motion_1"

# 簡易認証用シークレット（テスト中は省略可。本番運用では認証を推奨）
# Firebaseコンソール > プロジェクトの設定 > サービスアカウント > データベースの秘密
# を使う場合はここに入れて、リクエストURLに ?auth=xxx を付与する
FIREBASE_AUTH_SECRET = ""  # 空文字なら認証なしでアクセス（テストモードのDBルール用）

# --- 人感センサ設定 ---
MOTION_SENSOR_PIN = 27  # 人感センサ(PIRセンサ等)を接続したGPIO番号
CHECK_INTERVAL_SEC = 0.5  # センサを確認する間隔（秒）


# ============================================================
# 2. Wi-Fi接続
# ============================================================
def connect_wifi(ssid, password, timeout_sec=15):
    """Wi-Fiに接続する。接続できたらTrue、タイムアウトしたらFalseを返す。"""
    wlan = network.WLAN(network.STA_IF)
    wlan.active(True)

    if wlan.isconnected():
        print("Wi-Fi: already connected:", wlan.ifconfig())
        return True

    print("Wi-Fi: connecting to", ssid, "...")
    wlan.connect(ssid, password)

    start = time.time()
    while not wlan.isconnected():
        if time.time() - start > timeout_sec:
            print("Wi-Fi: connection timed out")
            return False
        time.sleep(0.5)

    print("Wi-Fi: connected:", wlan.ifconfig())
    return True


# ============================================================
# 3. Firebase Realtime Database への送信
# ============================================================
def build_firebase_url(path, auth_secret=""):
    #"""Realtime Database REST APIのURLを組み立てる。"""
    url = FIREBASE_URL.rstrip("/") + path + ".json"
    if auth_secret:
        url += "?auth=" + auth_secret
    return url


def send_motion_event(motion_detected):
    #"""
    #人感センサの検知結果をFirebase Realtime Databaseに送信する。

    #送信されるデータ構造（例）:
    {
        "detected": true,
        "timestamp": 123456789   # ESP32起動からの経過ミリ秒（簡易タイムスタンプ）
    }

    #本格的に時刻同期したい場合は ntptime モジュール等で
    #実時刻を取得してから timestamp に入れることをおすすめします。
    
    url = build_firebase_url(DB_PATH, FIREBASE_AUTH_SECRET)

    payload = {
        "detected": motion_detected,
        "timestamp": time.ticks_ms(),
    }

    try:
        response = urequests.put(url, json=payload)
        print("Firebase送信成功:", response.status_code, response.text)
        response.close()
        return True
    except Exception as e:
        print("Firebase送信エラー:", e)
        return False


# ============================================================
# 4. 人感センサの読み取り
#    ※ ここをチームメンバーのセンサ読み取りコードに
#       置き換えれば、そのまま統合できます。
# ============================================================
def setup_motion_sensor(pin_no):
    #"""人感センサ用のGPIOピンを初期化する。"""
    return Pin(pin_no, Pin.IN)


def read_motion_sensor(sensor_pin):
    #"""
    #人感センサの状態を読み取る。
    検知あり: True / 検知なし: False
    #多くのPIRセンサは検知時にHIGHを出力する想定。
    #センサの仕様に応じて反転させてください）
    #"""
    return sensor_pin.value() == 1


#============================================================
#5. メインループ
#============================================================
def main():
    if not connect_wifi(WIFI_SSID, WIFI_PASSWORD):
        print("Wi-Fi接続に失敗したため終了します")
        return

    motion_sensor = setup_motion_sensor(MOTION_SENSOR_PIN)

    #直前の状態を保持し、「状態が変化した時だけ」送信することで
    #同じ内容を何度も送り続けないようにする
    previous_state = False

    print("人感センサの監視を開始します...")

    while True:
        current_state = read_motion_sensor(motion_sensor)

        if current_state != previous_state:
            print("状態変化を検知:", "検知あり" if current_state else "検知なし")
            send_motion_event(current_state)
            previous_state = current_state

        time.sleep(CHECK_INTERVAL_SEC)


if __name__ == "__main__":
    main()
