#!/bin/bash

# Получаем адрес HTTPS-туннеля из локального API ngrok
NGROK_API="http://127.0.0.1:4040/api/tunnels"
ADDRESS=$(curl -s $NGROK_API | grep -o 'https://[^"]*ngrok-free.app' | head -n 1)

# Если адрес найден — записываем в файл
if [ ! -z "$ADDRESS" ]; then
    echo "$ADDRESS" > /root/current_address.txt
    echo "Ngrok адрес обновлён: $ADDRESS"
else
    echo "Не удалось получить адрес от ngrok"
fi
