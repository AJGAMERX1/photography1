#!/bin/bash
set -e

echo "Stripping leading underscores from filenames (GitHub Pages blocks these)..."
find images/fulls -type f -iname "_*.jpg" | while read -r f; do
  dir=$(dirname "$f")
  base=$(basename "$f")
  mv "$f" "$dir/${base#_}"
done

echo "Resizing images/fulls into images/thumbs (mirroring folders)..."
rm -rf images/thumbs
find images/fulls -type f -iname "*.jpg" | while read -r f; do
  rel="${f#images/fulls/}"
  dest="images/thumbs/$rel"
  mkdir -p "$(dirname "$dest")"
  magick "$f" -resize 512x512\> -quality 85 "$dest"
done

echo "Resizing images/Prints into images/print-thumbs..."
rm -rf images/print-thumbs
if [ -d images/Prints ]; then
  find images/Prints -type f -iname "_*.jpg" | while read -r f; do
    mv "$f" "$(dirname "$f")/$(basename "$f" | sed 's/^_*//')"
  done
  find images/Prints -type f -iname "*.jpg" | while read -r f; do
    rel="${f#images/Prints/}"
    dest="images/print-thumbs/$rel"
    mkdir -p "$(dirname "$dest")"
    magick "$f" -resize 512x512\> -quality 85 "$dest"
  done
fi

echo "Rebuilding gallery from folder structure..."
python3 << 'PYEOF'
import os, re

CAMERA_LABEL = { 'r6ii': 'Canon R6 Mark II', '7d': 'Canon 7D', 'g7x': 'PowerShot G7 X Mark II' }

entries = []
themes = set()

for cam in sorted(os.listdir('images/fulls')):
    cam_path = os.path.join('images/fulls', cam)
    if not os.path.isdir(cam_path): continue
    for theme in sorted(os.listdir(cam_path)):
        theme_path = os.path.join(cam_path, theme)
        if not os.path.isdir(theme_path): continue
        themes.add(theme)
        for fname in sorted(os.listdir(theme_path)):
            if not fname.lower().endswith('.jpg'): continue
            full = f"images/fulls/{cam}/{theme}/{fname}"
            thumb = f"images/thumbs/{cam}/{theme}/{fname}"
            label = os.path.splitext(fname)[0]
            entries.append(f"    {{ thumb: '{thumb}', full: '{full}', label: '{label}', cam: '{cam}', theme: '{theme}' }},")

with open('index.html') as fh:
    content = fh.read()

new_array = "const photos = [\n" + "\n".join(entries) + "\n  ];"
content = re.sub(r"const photos = \[.*?\];", new_array, content, flags=re.DOTALL)

theme_opts = "\n".join(f'      <option value="{t}">{t.title()}</option>' for t in sorted(themes))
content = re.sub(
    r'(<select class="theme-select" id="themeFilter">\s*<option value="all">All Themes</option>\n)(.*?)(\s*</select>)',
    lambda m: m.group(1) + theme_opts + m.group(3),
    content, flags=re.DOTALL
)

with open('index.html', 'w') as fh:
    fh.write(content)

print(f"index.html: {len(entries)} photos across {len(themes)} themes.")
PYEOF

echo "Building store-data.js from the same folder structure..."
python3 << 'PYEOF'
import os, json

CAMERA_LABEL = { 'r6ii': 'Canon R6 Mark II', '7d': 'Canon 7D', 'g7x': 'PowerShot G7 X Mark II' }

# Hand-maintained filename -> verse reference map. There's no way to detect which
# verse a photo actually shows, so this is the one place that knowledge lives.
# Anything missing or blank falls back to a generic "Verse N".
VERSE_LABELS = {}
if os.path.exists('verses.json'):
    with open('verses.json') as fh:
        VERSE_LABELS = {
            k: v for k, v in json.load(fh).items()
            if not k.startswith('_') and v.strip()
        }

# ---------------------------------------------------------------------------
# WHAT IS SOLD  ->  images/Prints/
#
# Drop your best work in there and it is offered as a print. Nothing else is.
# The FILENAME IS THE TITLE, so "Cold Moon.jpg" is sold as "Cold Moon" -- no
# list to maintain anywhere. Two layouts both work:
#
#     images/Prints/Cold Moon.jpg              <- flat
#     images/Prints/7d/Cold Moon.jpg           <- camera subfolder
#
# Laid out flat, the camera and theme are recovered by matching the filename
# back to images/fulls, so a straight copy keeps its metadata. If the file was
# renamed and can't be matched, it is still sold, just without a camera tag.
#
# An empty Prints folder means "offer everything", so the store keeps working
# before it is curated.
# ---------------------------------------------------------------------------
PRINTS_DIR = 'images/Prints'

# Index images/fulls so a print can be traced back to its camera/theme.
# Indexed by CONTENT HASH as well as by name: the whole point of this folder is
# that you rename files to title them, which destroys a name-based lookup. A
# straight copy keeps its bytes, so the hash still finds it.
import hashlib
def _digest(path):
    h = hashlib.md5()
    with open(path, 'rb') as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b''):
            h.update(chunk)
    return h.hexdigest()

fulls_by_name = {}
fulls_by_hash = {}
for cam in sorted(os.listdir('images/fulls')):
    cp = os.path.join('images/fulls', cam)
    if not os.path.isdir(cp): continue
    for theme in sorted(os.listdir(cp)):
        tp = os.path.join(cp, theme)
        if not os.path.isdir(tp): continue
        for fn in os.listdir(tp):
            if not fn.lower().endswith('.jpg'): continue
            fulls_by_name.setdefault(fn.lower(), (cam, theme))
            fulls_by_hash.setdefault(_digest(os.path.join(tp, fn)), (cam, theme))

def trace(path, fn):
    """camera/theme for a print: by content first, then by name."""
    hit = fulls_by_hash.get(_digest(path))
    if hit: return hit
    return fulls_by_name.get(fn.lower(), ('', ''))

def prints_entries():
    out = []
    if not os.path.isdir(PRINTS_DIR):
        return out
    for root, _dirs, files in os.walk(PRINTS_DIR):
        for fn in sorted(files):
            if not fn.lower().endswith('.jpg'): continue
            abs_p = os.path.join(root, fn)
            rel   = os.path.relpath(abs_p, PRINTS_DIR)        # e.g. "7d/Cold Moon.jpg"
            parts = rel.split(os.sep)
            # images/Prints/<cam>/<theme>/file.jpg -- both folder levels optional
            cam   = parts[0] if len(parts) > 1 else ''
            t_cam, t_theme = trace(abs_p, fn)
            if not cam:
                cam = t_cam                                    # flat: trace it back
            theme = parts[1] if len(parts) > 2 else t_theme
            out.append({
                "src":   abs_p,
                "rel":   rel,
                "title": os.path.splitext(fn)[0],              # filename IS the title
                "cam":   cam,
                "theme": theme or 'prints',
            })
    return out

PRINTS = prints_entries()
CURATED = bool(PRINTS)

photos = []
verses = []
verse_count = 0

if CURATED:
    # Sold work comes from images/Prints. Thumbs are generated next to it so the
    # store never has to reach back into the gallery's own thumbs.
    for e in PRINTS:
        photos.append({
            "thumb": 'images/print-thumbs/' + e['rel'].replace(os.sep, '/'),
            "full":  e['src'].replace(os.sep, '/'),
            "label": e['title'],
            "cam":   e['cam'],
            "theme": e['theme'],
        })
        if e['theme'].lower() == 'bible':
            verse_count += 1
            verses.append({
                "full": e['src'].replace(os.sep, '/'),
                "label": VERSE_LABELS.get(os.path.basename(e['src']), f"Verse {verse_count}")
            })
    untagged = [p['label'] for p in photos if not p['cam']]
    if untagged:
        print(f"  note: {len(untagged)} print(s) have no camera tag "
              f"(renamed, so not traceable to images/fulls) -- they still sell fine.")
else:
    # Nothing curated yet: offer the whole gallery so the store still works.
    for cam in sorted(os.listdir('images/fulls')):
        cam_path = os.path.join('images/fulls', cam)
        if not os.path.isdir(cam_path): continue
        for theme in sorted(os.listdir(cam_path)):
            theme_path = os.path.join(cam_path, theme)
            if not os.path.isdir(theme_path): continue
            for fname in sorted(os.listdir(theme_path)):
                if not fname.lower().endswith('.jpg'): continue
                rel = f"{cam}/{theme}/{fname}"
                photos.append({
                    "thumb": f"images/thumbs/{rel}", "full": f"images/fulls/{rel}",
                    "label": os.path.splitext(fname)[0], "cam": cam, "theme": theme
                })
                if theme.lower() == "bible":
                    verse_count += 1
                    verses.append({"full": f"images/fulls/{rel}",
                                   "label": VERSE_LABELS.get(fname, f"Verse {verse_count}")})

with open('store-data.js', 'w') as fh:
    fh.write("// Auto-generated by rebuild.sh — do not hand-edit, re-run the script instead.\n")
    fh.write("const CAMERA_LABEL = " + json.dumps(CAMERA_LABEL, indent=2) + ";\n")
    fh.write("const STORE_PHOTOS = " + json.dumps(photos, indent=2) + ";\n")
    fh.write("const STORE_VERSES = " + json.dumps(verses, indent=2) + ";\n")

named = sum(1 for v in verses if not v['label'].startswith('Verse '))
mode = "curated from images/Prints" if CURATED else "ALL gallery photos (images/Prints is empty)"
print(f"store-data.js: {len(photos)} photos offered for print -- {mode}.")
if named < len(verses):
    print("  -> add the missing verse references in verses.json, then re-run.")
PYEOF

echo "Stamping store-data.js with a cache-busting version..."
python3 << 'PYEOF'
import re, time
# Browsers happily serve a cached store-data.js after a rebuild, which would show
# returning visitors the old catalogue. Stamp the tag so each rebuild is a new URL.
stamp = str(int(time.time()))
s = open('store.html').read()
s = re.sub(r'<script src="store-data\.js(?:\?v=\d+)?"></script>',
           f'<script src="store-data.js?v={stamp}"></script>', s)
open('store.html','w').write(s)
print(f"store.html: store-data.js?v={stamp}")
PYEOF

echo "Cleaning up loose files in images/ root..."
rm -f images/*.jpg

echo "Done."
