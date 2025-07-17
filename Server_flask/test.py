import requests
import time
import os

print("Мониторинг запущен")

# Настройки
CURRENT_ADDRESS_FILE = "current_address.txt"
TELEGRAM_BOT_TOKEN = "7652984987:AAEgaoQGVrLXrC6bAAbrEa77rHBUIggpa2c"
CHAT_ID = "725543653"

# Функция для получения текущего адреса из файла
def get_ngrok_url():
    if not os.path.exists(CURRENT_ADDRESS_FILE):
        print("[!] Файл с адресом ngrok не найден.")
        return None
    with open(CURRENT_ADDRESS_FILE, "r") as f:
        url = f.read().strip()
    return url if url.startswith("http") else None

# Отправка сообщения в Telegram
def send_telegram_message(text):
    url = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendMessage"
    payload = {
        "chat_id": CHAT_ID,
        "text": text
    }
    try:
        response = requests.post(url, json=payload)
        response.raise_for_status()
    except requests.RequestException as e:
        print(f"[Telegram Error] {e}")

# Проверка доступности ngrok-адреса
def check_ngrok():
    url = get_ngrok_url()
    if not url:
        send_telegram_message("⚠️ Не удалось получить адрес ngrok из файла.")
        return

    try:
        response = requests.get(url, timeout=5)
        if response.status_code == 200:
            print(f"[OK] {url} доступен.")
            send_telegram_message(f"[OK] {url} доступен.")
        else:
            print(f"[!] {url} вернул код: {response.status_code}")
            send_telegram_message(f"⚠️ NGROK вернул ошибку: {response.status_code}")
    except requests.RequestException:
        print(f"[X] {url} недоступен.")
        send_telegram_message(f"❌ NGROK недоступен: {url}")

# Цикл проверки каждые 5 минут
if __name__ == "__main__":
    while True:
        check_ngrok()
        time.sleep(1800)  # 5 минут
