"""Makes the Windows shell commands built in windows.rs survive an app name with a space.

Upstream puts the app name into `reg`, `sc` and `taskkill` commands without quotes
(HKCR/<name>, .../Uninstall/<name>, sc create <name>, taskkill /IM <name>.exe).
With "INTO Remote" the unquoted form breaks: registry keys are cut at the space and the
Windows service is never created, so nothing starts after a reboot.
Run from the root of the RustDesk checkout.
"""
import io
import re

PATH = "src/platform/windows.rs"
QUOTE = chr(92) + chr(34)  # backslash + double quote, as written inside a Rust string literal
END = r'(?=[ \n"{])'

RULES = [
    # reg add KEY ...  ->  reg add "KEY" ...
    ("registry keys", 40,
     re.compile(r'(reg (?:add|delete) )(HKEY_CLASSES_ROOT\S*\{ext\}\S*|\{subkey\}|\{\})' + END)),
    # sc create NAME ...  ->  sc create "NAME" ...
    ("service commands", 14,
     re.compile(r'(sc (?:create|start|stop|delete) )(\{app_name\}|\{\})' + END)),
    # taskkill /F /IM NAME.exe  ->  taskkill /F /IM "NAME.exe"
    ("taskkill commands", 4,
     re.compile(r'(taskkill /F /IM )(\{app_name\}\.exe|\{process_exe\})' + END)),
]

with io.open(PATH, encoding="utf-8") as f:
    src = f.read()
for name, minimum, pattern in RULES:
    src, count = pattern.subn(lambda m: m.group(1) + QUOTE + m.group(2) + QUOTE, src)
    if count < minimum:
        raise SystemExit("PATCH FAILED: %s, only %d matched in %s" % (name, count, PATH))
    print("windows.rs: %d %s quoted" % (count, name))
with io.open(PATH, "w", encoding="utf-8", newline="\n") as f:
    f.write(src)
