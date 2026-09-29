"""INTO colours inside the app (same palette as intomsp.com).

Replaces the upstream blue accent with INTO ember and the greys with the site's paper / ink tones.
Pure constant substitution in the Flutter sources. Run from the root of the RustDesk checkout.
"""
import io
import os

EMBER = "E8623D"
SWAPS_EVERYWHERE = {
    "0xFF0071FF": "0xFF" + EMBER,  # accent
    "0x770071FF": "0x77" + EMBER,
    "0xAA0071FF": "0xAA" + EMBER,
    "0xFF2C8CFF": "0xFF" + EMBER,  # buttons
}
SWAPS_COMMON = {
    "Color idColor = Color(0xFF00B6F0)": "Color idColor = Color(0xFF" + EMBER + ")",
    "Color grayBg = Color(0xFFEFEFF2)": "Color grayBg = Color(0xFFF6F5F1)",
    "primary: Colors.blue": "primary: Color(0xFF" + EMBER + ")",
    "0xFF18191E": "0xFF0E0E0C",  # dark surfaces
    "0xFF24252B": "0xFF1A1C1F",
}

total = 0
for root, _, files in os.walk("flutter/lib"):
    for name in files:
        if not name.endswith(".dart"):
            continue
        path = os.path.join(root, name)
        with io.open(path, encoding="utf-8") as f:
            src = f.read()
        out = src
        for old, new in SWAPS_EVERYWHERE.items():
            out = out.replace(old, new)
        if path.replace("\\", "/") == "flutter/lib/common.dart":
            for old, new in SWAPS_COMMON.items():
                if old not in out:
                    raise SystemExit("PATCH FAILED: theme constant not found: " + old)
                out = out.replace(old, new)
        if out != src:
            total += 1
            with io.open(path, "w", encoding="utf-8", newline="\n") as f:
                f.write(out)
if total == 0:
    raise SystemExit("PATCH FAILED: no theme colours replaced")
print("theme: %d dart files recoloured" % total)
