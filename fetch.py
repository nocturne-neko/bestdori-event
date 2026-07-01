#!/usr/bin/env python3
"""
Bestdori EN event widget fetcher.
Outputs a single JSON blob to stdout for Quickshell to consume.
Caches API responses and assets locally.
"""

import json
import os
import hashlib
import sys
import time
import urllib.request
import urllib.error

BASE = "https://bestdori.com"
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
CACHE_API = os.path.join(SCRIPT_DIR, "cache", "api")
CACHE_ASSETS = os.path.join(SCRIPT_DIR, "cache", "assets")

HEADERS = {
    "User-Agent": "Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0",
    "Accept": "application/json, */*",
}

os.makedirs(CACHE_API, exist_ok=True)
os.makedirs(CACHE_ASSETS, exist_ok=True)


def api_cache_path(path):
    """Turn /api/events/307.json into cache/api/events__307.json"""
    safe = path.lstrip("/").replace("/", "__")
    return os.path.join(CACHE_API, safe)


def asset_cache_path(url):
    """Hash URL for asset filename."""
    h = hashlib.md5(url.encode()).hexdigest()
    # Preserve extension from URL
    ext = url.rsplit(".", 1)[-1] if "." in url.split("/")[-1] else "bin"
    return os.path.join(CACHE_ASSETS, f"{h}.{ext}")


def get_api(path, cache=True):
    """Fetch a Bestdori API JSON endpoint. Optionally cache."""
    url = BASE + path

    if cache:
        cp = api_cache_path(path)
        if os.path.exists(cp):
            with open(cp, "r") as f:
                return json.load(f)

    req = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(req, timeout=10) as r:
        data = json.loads(r.read())

    if cache:
        cp = api_cache_path(path)
        with open(cp, "w") as f:
            json.dump(data, f)

    return data


def get_asset_url(url):
    """Return a local cached path for an asset, downloading if needed."""
    cp = asset_cache_path(url)
    if not os.path.exists(cp):
        try:
            req = urllib.request.Request(url, headers=HEADERS)
            with urllib.request.urlopen(req, timeout=15) as r:
                with open(cp, "wb") as f:
                    f.write(r.read())
        except Exception:
            return url  # fall back to remote URL on failure
    return "file://" + cp


def main():
    # Server index: JP=0, EN=1, TW=2, CN=3 (skip KR=4, EOS)
    server_index = int(sys.argv[1]) if len(sys.argv) > 1 else 1
    server_names = {0: "JP", 1: "EN", 2: "TW", 3: "CN"}
    server_name = server_names.get(server_index, "EN")

    # Region code for asset URLs
    server_regions = {0: "jp", 1: "en", 2: "tw", 3: "cn"}
    region = server_regions.get(server_index, "en")

    # 1. Get recent news (never cached)
    news = get_api("/api/news/dynamic/recent.json", cache=False)
    events = news.get("events", {})

    # 2. Find most recent event for selected server
    latest_id = None
    latest_start = 0
    for eid, ev in events.items():
        ev_start = ev.get("startAt", [None, None, None, None, None])
        if server_index < len(ev_start) and ev_start[server_index] and int(ev_start[server_index]) > latest_start:
            latest_start = int(ev_start[server_index])
            latest_id = eid

    if not latest_id:
        print(json.dumps({"error": f"no {server_name} event found"}))
        return

    # 3. Fetch event details (cached)
    event = get_api(f"/api/events/{latest_id}.json")

    event_type = event.get("eventType", "")
    banner_name = event.get("bannerAssetBundleName", "")
    banner_remote = f"{BASE}/assets/{region}/homebanner_rip/{banner_name}.png"
    banner_url = get_asset_url(banner_remote)

    event_name = event.get("eventName", [None] * 5)[server_index] or event.get("eventName", [None])[0] or ""

    # Attribute
    attributes = event.get("attributes", [])
    attribute = ""
    if attributes and isinstance(attributes, list):
        attribute = attributes[0].get("attribute", "")
    attribute_icon_remote = f"{BASE}/res/icon/{attribute}.svg" if attribute else ""
    attribute_icon_url = get_asset_url(attribute_icon_remote) if attribute_icon_remote else ""

    # 4. Determine Event Band
    char_to_band = {
        1: 1, 2: 1, 3: 1, 4: 1, 5: 1,       # Poppin'Party
        6: 2, 7: 2, 8: 2, 9: 2, 10: 2,       # Afterglow
        11: 3, 12: 3, 13: 3, 14: 3, 15: 3,   # Hello, Happy World!
        16: 4, 17: 4, 18: 4, 19: 4, 20: 4,   # Pastel*Palettes
        21: 5, 22: 5, 23: 5, 24: 5, 25: 5,   # Roselia
        26: 21, 27: 21, 28: 21, 29: 21, 30: 21,  # Morfonica
        31: 18, 32: 18, 33: 18, 34: 18, 35: 18,  # RAISE A SUILEN
        36: 45, 37: 45, 38: 45, 39: 45, 40: 45,  # MyGO!!!!!
    }

    band_names = {
        1: "Poppin'Party", 2: "Afterglow", 3: "Hello, Happy World!",
        4: "Pastel*Palettes", 5: "Roselia", 18: "RAISE A SUILEN",
        21: "Morfonica", 45: "MyGO!!!!!"
    }

    event_chars = event.get("characters", [])
    band_ids = set()
    for c in event_chars:
        cid = c.get("characterId")
        if cid in char_to_band:
            band_ids.add(char_to_band[cid])

    band_id = None
    band_name = "Mixed"
    band_icon_url = ""

    if len(band_ids) == 1:
        band_id = list(band_ids)[0]
        band_name = band_names.get(band_id, "Unknown")
        band_icon_remote = f"{BASE}/res/icon/band_{band_id}.svg"
        band_icon_url = get_asset_url(band_icon_remote)

    # 5. Fetch each member card (cached)
    members = event.get("members", [])
    cards = []
    for m in members:
        sid = m.get("situationId")
        if sid is None:
            continue
        try:
            card = get_api(f"/api/cards/{sid}.json")
            resource_set = card.get("resourceSetName", "")
            chunk_id = str(int(sid) // 50).zfill(5)
            icon_remote = f"{BASE}/assets/{region}/thumb/chara/card{chunk_id}_rip/{resource_set}_normal.png"
            icon_url = get_asset_url(icon_remote)
            
            # Fetch character name
            char_id = card.get("characterId")
            char_name = ""
            if char_id:
                try:
                    char_data = get_api(f"/api/characters/{char_id}.json")
                    char_names = char_data.get("characterName", [])
                    if server_index < len(char_names) and char_names[server_index]:
                        char_name = char_names[server_index]
                    elif char_names:
                        char_name = char_names[0]  # fallback to JP
                except Exception:
                    pass
            
            cards.append({
                "situationId": sid,
                "resourceSetName": resource_set,
                "chunkId": chunk_id,
                "attribute": card.get("attribute", ""),
                "characterId": char_id,
                "characterName": char_name,
                "rarity": card.get("rarity"),
                "iconUrl": icon_url,
            })
        except Exception:
            pass

    result = {
        "eventId": latest_id,
        "eventName": event_name,
        "eventType": event_type,
        "eventTypeDisplay": event_type.replace("_", " ").upper(),
        "bannerUrl": banner_url,
        "attribute": attribute,
        "attributeIconUrl": attribute_icon_url,
        "bandId": band_id,
        "bandName": band_name,
        "bandIconUrl": band_icon_url,
        "cards": cards,
        "server": server_name,
        "startAt": event.get("startAt", [None, None, None, None, None])[server_index],
        "endAt": event.get("endAt", [None, None, None, None, None])[server_index],
        "currentTimeMs": int(time.time() * 1000)
    }
    print(json.dumps(result))

if __name__ == "__main__":
    main()
