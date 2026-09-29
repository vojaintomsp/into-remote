"""Quotes the registry key argument of every `reg add` / `reg delete` built in windows.rs.

Upstream builds these commands with the app name inside the key (HKCR\\<name>, ...\\Uninstall\\<name>).
An app name with a space ("INTO Remote") needs the key in quotes:  reg add "KEY" /f ...
Run from the root of the RustDesk checkout.
"""
import io
import re

PATH = "src/platform/windows.rs"
KEY = re.compile(r'(reg (?:add|delete) )(HKEY_CLASSES_ROOT\S*\{ext\}\S*|\{subkey\}|\{\})(?=[ \n"])')

with io.open(PATH, encoding="utf-8") as f:
    src = f.read()
src, count = KEY.subn(lambda m: m.group(1) + '\\"' + m.group(2) + '\\"', src)
if count < 40:
    raise SystemExit("PATCH FAILED: only %d registry commands matched in %s" % (count, PATH))
with io.open(PATH, "w", encoding="utf-8", newline="\n") as f:
    f.write(src)
print("windows.rs: %d registry keys quoted" % count)
