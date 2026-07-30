#!/bin/bash
set -e

echo "Resizing images/fulls into images/thumbs (mirroring folders)..."
find images/fulls -type f -iname "*.jpg" | while read -r f; do
  rel="${f#images/fulls/}"
  dest="images/thumbs/$rel"
  mkdir -p "$(dirname "$dest")"
  magick "$f" -resize 512x512\> -quality 85 "$dest"
done

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

print(f"{len(entries)} photos across {len(themes)} themes.")
PYEOF
echo "Done."
