"""Encodes a custom client JSON into the base64 form the client reads from custom_.txt.

Server address and key come from the environment (SERVER_HOST, SERVER_KEY), never from the repository.
"""
import base64
import json
import os
import sys

src, dst = sys.argv[1], sys.argv[2]
with open(src, encoding="utf-8") as f:
    text = f.read()
for name in ("SERVER_HOST", "SERVER_KEY"):
    value = os.environ.get(name, "")
    if not value:
        raise SystemExit(name + " is not set")
    text = text.replace("@" + name + "@", value)
data = json.loads(text)
with open(dst, "w", encoding="ascii", newline="") as f:
    f.write(base64.b64encode(json.dumps(data).encode("ascii")).decode("ascii"))
print("%s -> %s" % (src, dst))
