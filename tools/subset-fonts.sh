#!/usr/bin/env bash
# Rebuild public/js/fonts.js from full TTF files.
# Needs: pip install fonttools brotli ; npm i @expo-google-fonts/arimo @expo-google-fonts/tinos @expo-google-fonts/cousine
# After running, bump ?v=N for js/fonts.js in public/index.html.
set -euo pipefail
U="U+0020-007E,U+00A0-024F,U+0259,U+02B0-02FF,U+0300-036F,U+1E00-1EFF,U+2000-206F,U+20A0-20CF,U+2100-2122,U+2190-2193,U+2212,U+2215,U+2219,U+221E,U+2248,U+2260,U+2264,U+2265,U+25CF,U+FB01,U+FB02"
OUT=tools/fonts-src/sub; mkdir -p "$OUT"
for fam in arimo tinos cousine; do
  for f in node_modules/@expo-google-fonts/$fam/*/*_{400Regular,400Regular_Italic,700Bold,700Bold_Italic}.ttf; do
    [ -f "$f" ] || continue
    pyftsubset "$f" --unicodes="$U" --no-hinting --desubroutinize \
      --layout-features='kern,ccmp,mark,mkmk' --output-file="$OUT/$(basename "$f")"
  done
done
python3 - "$OUT" <<'PY'
import base64,json,sys
d=sys.argv[1]
fam={'helv':'Arimo','times':'Tinos','cour':'Cousine'}
var={'r':'400Regular','i':'400Regular_Italic','b':'700Bold','bi':'700Bold_Italic'}
data={k:{v:base64.b64encode(open(f'{d}/{n}_{vv}.ttf','rb').read()).decode() for v,vv in var.items()} for k,n in fam.items()}
open('public/js/fonts.js','w').write('window.PB_FONTS='+json.dumps(data,separators=(',',':'))+';\n')
print('wrote public/js/fonts.js')
PY
