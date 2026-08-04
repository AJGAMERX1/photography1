# Room scene photo

The store's mockup hangs each print on a real room's wall. Drop a room photo in
this folder and point `ROOM.src` (top of the `<script>` in `store.html`) at it.
With `ROOM.src` left as `null`, the stage falls back to the plain flat wall, so
the page works fine before a photo is installed.

## Choosing a photo

Look for: a large blank wall area, the wall shot close to straight-on, soft even
daylight, and furniture in frame (a sofa, a door) so the eye gets real scale.
Avoid: wide-angle distortion, busy wallpaper, existing artwork on the wall, and
anything that looks AI-generated — soft/melted furniture edges, nonsense
reflections, warped outlet plates, and impossible perspective are the giveaways.

## Licensing — read before committing anything here

This is a **commercial storefront**, so the photo's licence matters.

- **Safest: public domain / CC0.** No restrictions, no attribution obligation.
  Wikimedia Commons (filter to PD or CC0) and other PD collections.
- **Usually fine: Pexels / Unsplash.** Both permit commercial use with no
  attribution, and a mockup background is squarely within that. Note that
  Unsplash's terms specifically prohibit **selling their photos as prints or on
  physical goods** — not an issue for a background, but it is a real constraint
  to stay aware of on a site that sells prints.
- **Avoid** anything scraped from Google Images, Pinterest, or a retailer's own
  product photography — retailer mockups are typically all-rights-reserved.

Record what you used below so the provenance isn't lost.

If the photo's licence asks for credit, set `ROOM.creditText` / `ROOM.creditHref`
and it renders as a small link in the corner of the scene.

## Installed photo

| Field | Value |
|---|---|
| File | _(none yet)_ |
| Source URL | |
| Photographer | |
| Licence | |
| Date added | |

## Calibrating

Three numbers in the `ROOM` object make the scale honest:

- `anchorXPct` / `anchorYPct` — where the centre of the print sits, as a % of the
  photo. Aim for the middle of the blank wall.
- `pxPerInchAtWall` — measure something of known size **on that same wall** in
  the photo (an interior door is ~30in wide, a standard sofa ~84in) and divide
  its width in pixels by its width in inches. This is the number that makes an
  8x12 and a 24x36 genuinely different sizes on the wall.
- `rotateY` / `rotateX` — match the wall's perspective. Use `0` for a wall shot
  straight on; a few degrees if the camera was angled.
