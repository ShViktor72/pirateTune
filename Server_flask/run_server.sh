#!/usr/bin/bash

MYENV="/root/myenv"
FLASK_APP="/root/main.py"
NGROK_BIN="/usr/local/bin/ngrok"
PORT=5000
PUBLIC_URL="mako-happy-adversely.ngrok-free.app"  

start_flask() {
  source $MYENV/bin/activate
  nohup python3 $FLASK_APP > flask.log 2>&1 &
  echo $! > flask.pid
  deactivate
}

start_ngrok() {
  nohup $NGROK_BIN start --all > ngrok.log 2>&1 &
  echo $! > ngrok.pid
}

stop_old_processes() {
  for pidfile in flask.pid ngrok.pid test.pid; do
    if [ -f "$pidfile" ]; then
      kill $(cat "$pidfile") 2>/dev/null
      rm "$pidfile"
    fi
  done
}

# Основной запуск
stop_old_processes
start_flask
sleep 3
start_ngrok
sleep 3
start_monitor

# Запись и вывод URL
echo "$PUBLIC_URL" > /root/current_address.txt
echo "Все сервисы запущены"
echo "Адрес API: $PUBLIC_URL"

sleep infinity


