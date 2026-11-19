"""Convertit le recueil validé (export Markdown du document Claude) en www/cantiques.json.

Usage : python extract.py <fichier .md ou dossier recueil> <sortie cantiques.json>
Si un dossier est donné, le fichier .md le plus récent est utilisé.
Les cantiques sont triés par ordre alphabétique du titre (accents et majuscules ignorés).
"""
import html
import json
import re
import sys
import unicodedata
from datetime import datetime
from pathlib import Path

LANGS = {"francais": "fr", "français": "fr", "english": "en", "anglais": "en"}
# Toute autre langue (Zoulou, Afrikaans, Espagnol, Swahili…) va dans "other", avec son nom.


def sort_key(title):
    s = unicodedata.normalize("NFKD", title.lower().replace("œ", "oe").replace("æ", "ae"))
    s = "".join(c for c in s if not unicodedata.combining(c))
    s = re.sub(r"[^a-z0-9 ]", " ", s)
    return re.sub(r"\s+", " ", s).strip()


def clean(line):
    line = html.unescape(line)
    line = re.sub(r"\\$", "", line.rstrip())          # saut de ligne Markdown « \ » en fin de ligne
    line = re.sub(r"\\([\\`*_{}\[\]()#+\-.!|<>~])", r"\1", line)  # caractères échappés
    line = re.sub(r"(\*\*|__)(.*?)\1", r"\2", line)    # gras
    return line.strip()


def parse(text):
    songs, cur, lang = [], None, None
    stanza = []

    def flush():
        nonlocal stanza
        if cur is not None and lang and stanza:
            if lang in ("fr", "en"):
                cur[lang].append(stanza)
            else:
                cur["other"][-1]["stanzas"].append(stanza)
        stanza = []

    for raw in text.splitlines():
        line = raw.rstrip()
        m = re.match(r"^##\s+(.+?)\s*$", line)
        if m and not line.startswith("###"):
            flush()
            title = clean(m.group(1))
            title = re.sub(r"^C\d{4}\s*[·\-–]\s*", "", title)  # au cas où l'ID est dans le titre
            cur = {"id": "", "title": title, "fr": [], "en": [], "other": []}
            songs.append(cur)
            lang = None
            continue
        if cur is None:
            continue
        if not line.strip():
            flush()
            continue
        m = re.match(r"^ID\s*:\s*(C\d+)", clean(line))
        if m:
            cur["id"] = m.group(1)
            continue
        if re.match(r"^\s*Statut\s*:", clean(line)):
            continue
        m = re.match(r"^\*\*([^*\\]+?)\*\*\s*\\?\s*$", line.strip().replace("****", ""))
        if m:
            flush()
            name = m.group(1).strip()
            lang = LANGS.get(name.lower())
            if not lang:
                lang = "other"
                cur["other"].append({"lang": name[:1].upper() + name[1:], "stanzas": []})
            continue
        if lang:
            c = clean(line)
            if c:
                stanza.append(c)
    flush()
    for s in songs:
        s["other"] = [o for o in s["other"] if o["stanzas"]]
        if not s["other"]:
            del s["other"]
    return [s for s in songs if s["fr"] or s["en"] or s.get("other")]


def main():
    src, out = Path(sys.argv[1]), Path(sys.argv[2])
    if src.is_dir():
        mds = sorted(src.glob("*.md"), key=lambda p: p.stat().st_mtime, reverse=True)
        if not mds:
            sys.exit(f"Aucun fichier .md dans {src}")
        src = mds[0]
    print(f"Source : {src.name}")
    songs = parse(src.read_text(encoding="utf-8-sig"))
    songs.sort(key=lambda s: sort_key(s["title"]))
    ids = [s["id"] for s in songs if s["id"]]
    dup = {i for i in ids if ids.count(i) > 1}
    for s in songs:
        flags = []
        if not s["id"]:
            flags.append("⚠ sans ID")
        if s["id"] in dup:
            flags.append("⚠ ID en double")
        if not s["fr"]:
            flags.append("sans français")
        if not s["en"]:
            flags.append("sans anglais")
        if s.get("other"):
            flags.append("autres langues : " + ", ".join(o["lang"] for o in s["other"]))
        print(f"  {s['id'] or '-----'}  {s['title']}" + (f"   ({', '.join(flags)})" if flags else ""))
    old = []
    if out.exists():
        try:
            old = json.loads(out.read_text(encoding="utf-8")).get("songs", [])
        except Exception:
            pass
    old_ids = {s.get("id") or s.get("title") for s in old}
    new = [s for s in songs if (s["id"] or s["title"]) not in old_ids]
    data = {"version": datetime.now().strftime("%Y-%m-%dT%H:%M:%S"), "count": len(songs), "songs": songs}
    out.write_text(json.dumps(data, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(f"\n{len(songs)} cantiques enregistrés ({len(new)} nouveaux) dans {out}")


if __name__ == "__main__":
    main()
