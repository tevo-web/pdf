# PDF Bench

In-browser PDF editor published by Tevo. Static site, no backend: every PDF is
opened, edited and saved inside the user's browser and never uploaded. Keep it
that way; do not add any feature that sends document content to a server.

## Stack and layout

- Plain HTML/CSS/JS, no framework, no build step. Do not introduce a bundler
  or npm build unless asked.
- `public/` is the deployed folder (Cloudflare Workers static assets, see `wrangler.jsonc`).
  - `index.html` holds all markup, CSS and application JS (one IIFE).
  - `js/pdf.min.js`, `js/pdf.worker.min.js`: pdf.js 3.11.174 (UMD, global `pdfjsLib`). Renders pages and extracts text.
  - `js/pdf-lib.min.js`: pdf-lib 1.17.1 (global `PDFLib`). Writes the output PDF.
  - `js/fontkit.umd.min.js`: @pdf-lib/fontkit 1.1.1 (global `fontkit`). Embeds TTF fonts.
  - `js/fonts.js`: `window.PB_FONTS`, base64 TTFs for Arimo, Tinos, Cousine
    (regular/italic/bold/bold-italic), subset to Latin + Vietnamese. Rebuild with `tools/subset-fonts.sh`.
  - `_headers`: security headers, CSP and caching.
  - `licenses/`: third-party notices. Must ship with the site.
- Other files at repo root are not deployed.

## How the editor works (read before changing index.html)

- State: `pages[]`, each `{id, src, base, rot, view:[x0,y0,x1,y1], objs:[]}`.
  `src` is the page index in the original PDF (`null` for inserted blank pages),
  `base` is the page's own /Rotate, `rot` is the user's extra rotation, `view` is the crop box in PDF points.
- Objects in `objs` are stored in **display points at zoom 1 in the page's current rotated orientation**
  (top-left origin). Types: `text`, `whiteout`, `highlight`, `rect`, `ellipse`, `draw` (normalised `pts`), `image` (bytes in `images{}`).
- `toPdf(page, x, y)` converts display points to PDF user space for rotations 0/90/180/270.
  Export draws with `rotate: degrees(rotOf(page))` anchored at the bottom-left corner of each box.
- Text: `measure(o)` uses canvas metrics of the embedded font to get width, line height (1.2 × size)
  and baseline offset. The same numbers drive on-screen layout and export, so they must stay in sync.
  Export uses the embedded Unicode font; it falls back to a PNG only if a glyph is missing.
- "Edit text" reads pdf.js `getTextContent()`, places a whiteout over the original run and a new
  text object on the same baseline. Original content is covered, not removed.
- History: `snap()` / `record(prev)` store JSON snapshots of `pages` (undo/redo, max 200).
- Saving: `buildPdf()` copies source pages with pdf-lib, applies rotation, draws objects.
  `savePdf()` uses the Claude artifact `downloads` capability when present, otherwise a blob download.

## Conventions

- **UI text:** every user-facing string goes through `tr(key, ...args)`. Add the key to both
  `L.en` and `L.vi`. English is the default language. Static markup uses `data-i18n`,
  `data-i18n-title`, `data-i18n-aria`.
- **Inline styles in template strings:** wrap any value that can contain quotes with `esc()`.
  Font family lists use single quotes. (A double quote inside `style="…"` once broke text rendering.)
- **Colors:** use the CSS tokens on `:root` and keep the dark-mode blocks in sync.
- **Cache busting:** files in `public/js/` are cached for a year. When one changes, bump its
  `?v=N` in `index.html` (and the worker URL in `GlobalWorkerOptions.workerSrc`).
- **CSP:** `_headers` only allows same-origin scripts plus Google Fonts. Adding analytics,
  ads or any external script requires updating the CSP in the same change.
- Keep the page working at 400px wide (the props panel becomes a bottom sheet under 900px).

## Checking changes

No automated tests yet. Before opening a PR:
1. `cd public && python3 -m http.server 8080`, open http://localhost:8080.
2. Open the sample document and one real PDF (ideally one with rotated pages).
3. Try: Edit text on existing text, Add text with Vietnamese diacritics, whiteout, highlight,
   rectangle, draw, image, rotate/reorder/delete page, undo/redo, switch language, Save PDF.
4. Open the saved PDF in a second viewer (Chrome and Acrobat/Preview) and check text position,
   font, size, colour and that Vietnamese text is selectable.
5. No errors in the browser console.

## Deploy

- Cloudflare Workers Builds is connected to this GitHub repo.
- Push/merge to `main` → production deploy (`npx wrangler deploy`).
- Other branches / PRs → preview URL posted on the PR.
- Work on a branch and open a PR; do not push straight to `main` unless asked.
