# Prints — the work that is for sale

Drop a photo in this folder and it is offered as a print. Nothing outside this
folder is sold, so the gallery can stay large while the shop stays selective.

**The filename is the title.** `Cold Moon.jpg` is sold as "Cold Moon". There is
no list to maintain.

Two layouts both work:

    images/Prints/Cold Moon.jpg          <- flat, simplest
    images/Prints/7d/Cold Moon.jpg       <- camera subfolder, keeps the camera filter

Laid out flat, the camera is recovered by matching the filename back to
images/fulls — so a straight copy keeps its metadata. Rename the file and it
still sells, just without a camera tag (rebuild.sh tells you when that happens).
Put it in a camera subfolder if you want the tag *and* a custom title.

Use the full-resolution original here, not a thumbnail — this is what gets sent
to the lab. Thumbnails are generated automatically into images/print-thumbs.

After adding or removing anything:

    ./rebuild.sh

An empty folder means "offer everything", so the store keeps working before you
have curated it.
