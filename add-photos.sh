#!/bin/bash
set -e

if [ -z "$1" ]; then
  echo "Usage: ./add-photos.sh /path/to/folder-of-new-photos"
  exit 1
fi

SRC="$1"

echo "Copying photos from $SRC..."
cp "$SRC"/*.jpg images/

echo "Resizing into fulls/ and thumbs/..."
npx gulp resize-images

echo "Building index.html entries..."
ENTRIES=""
for f in "$SRC"/*.jpg; do
  name=$(basename "$f")
  label="${name%.*}"
  ENTRIES="${ENTRIES}    { thumb: 'images/thumbs/${name}', full: 'images/fulls/${name}', label: '${label}', cam: 'unknown' },
"
done

awk -v entries="$ENTRIES" '
  /^  \];$/ && !inserted { printf "%s", entries; inserted=1 }
  { print }
' index.html > index.html.tmp && mv index.html.tmp index.html

echo "Cleaning up loose files in images/ root..."
rm -f images/*.jpg

echo "Done. New photos added to index.html — review with: git diff index.html"
echo "Then push with: git add -A && git commit -m 'Add new photos' && git push"
