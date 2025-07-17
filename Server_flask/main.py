# main.py
from flask import Flask, request, jsonify
import requests
from bs4 import BeautifulSoup
from datetime import datetime

app = Flask(__name__)
LOG_FILE = "server.log"

def log_query(query):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(f"{timestamp} — query: {query}\n")

@app.route('/')
def index():
    return 'Сервер работает', 200

def search_tracks(query):
    url = f"https://muzofond.fm/search/{query}"
    headers = {
        "User-Agent": "Mozilla/5.0 (X11; Linux armv7l) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36"
    }

    response = requests.get(url, headers=headers)
    soup = BeautifulSoup(response.text, 'html.parser')

    query_words = query.lower().split("+")
    tracks = []
    play_buttons = soup.select("li.play")

    for i, play_btn in enumerate(play_buttons):
        parent_li = play_btn.find_parent("li")

        artist_element = parent_li.select_one("div.desc h3 span.artist")
        track_element = parent_li.select_one("div.desc h3 span.track")
        mp3_url = play_btn.get("data-url")

        if artist_element and track_element and mp3_url:
            artist = artist_element.text.strip()
            title = track_element.text.strip()
            match_count = sum(1 for word in query_words if word in (artist + " " + title).lower())

            tracks.append({
                "id": i + 1,
                "artist": artist,
                "title": title,
                "url": mp3_url,
                "matches": match_count
            })

    tracks.sort(key=lambda x: (-x['matches'], x['id']))

    for track in tracks:
        track.pop('matches')

    return tracks

@app.route("/api/search")
def search():
    query = request.args.get("q")
    if not query:
        return jsonify({"error": "Missing 'q' parameter"}), 400

    log_query(query)
    tracks = search_tracks(query)
    return jsonify(tracks)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)


