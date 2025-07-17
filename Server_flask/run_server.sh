#!/usr/bin/bash

MYENV="/root/myenv"
FLASK_APP="/root/main.py"
NGROK_BIN="/usr/local/bin/ngrok"
TEST_MONITOR="/root/test.py"

PORT=5000

start_flask() {
  source $MYENV/bin/activate
  nohup python3 $FLASK_APP > flask.log 2>&1 &
  echo $! > flask.pid
  deactivate
}

start_ngrok() {
  nohup $NGROK_BIN http $PORT --log=ngrok.log > /dev/null 2>&1 &
  echo $! > ngrok.pid
}

update_ngrok_url() {
  echo "Жду ngrok..."
  while true; do
    ADDRESS=$(curl -s http://127.0.0.1:4040/api/tunnels | grep -o 'https://[^"]*ngrok-free.app' | head -n 1)
    if [ ! -z "$ADDRESS" ]; then
      echo "$ADDRESS" > /root/current_address.txt
      echo "Ngrok запущен: $ADDRESS"
      break
    fi
    sleep 2
  done
}

start_monitor() {
  source $MYENV/bin/activate
  nohup python3 $TEST_MONITOR > test.log 2>&1 &
  echo $! > test.pid
  deactivate
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
update_ngrok_url
start_monitor

echo "Все сервисы запущены"
echo "Адрес API: $(cat /root/current_address.txt)"
sleep infinity


