#!/usr/bin/bash

MYENV="/root/myenv"
FLASK_APP="/root/main.py"
NGROK_BIN="/usr/local/bin/ngrok"

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


stop_old_processes() {
  if [ -f flask.pid ]; then
    kill $(cat flask.pid) 2>/dev/null
    rm flask.pid
  fi
  if [ -f ngrok.pid ]; then
    kill $(cat ngrok.pid) 2>/dev/null
    rm ngrok.pid
  fi
}

stop_old_processes
start_flask
sleep 3
start_ngrok
sleep 3
update_ngrok_url

echo "server and ngrok runned"
echo "address API: $(cat /root/current_address.txt)"
sleep infinity
