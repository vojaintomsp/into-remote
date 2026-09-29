"""Encodes a custom client JSON into the base64 form the client reads from custom_.txt."""
import base64
import json
import sys

src, dst = sys.argv[1], sys.argv[2]
with open(src, encoding="utf-8") as f:
    data = json.load(f)
with open(dst, "w", encoding="ascii", newline="") as f:
    f.write(base64.b64encode(json.dumps(data).encode("ascii")).decode("ascii"))
print(f"{src} -> {dst}")
