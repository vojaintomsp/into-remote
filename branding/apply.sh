#!/usr/bin/env bash
# Applies INTO Remote branding on top of an unmodified RustDesk source tree.
# Usage: run from the root of the RustDesk checkout:  bash <path>/branding/apply.sh
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$HERE/config.env"
: "${SERVER_HOST:?SERVER_HOST is not set}" "${SERVER_KEY:?SERVER_KEY is not set}"

need() { [ -f "$1" ] || { echo "missing: $1"; exit 1; }; }
need ./libs/hbb_common/src/config.rs; need ./src/common.rs; need ./Cargo.toml
# every replacement must actually hit, otherwise upstream changed and we want to know
rep() { # rep <file> <sed-expr> <grep-check>
  sed -i -e "$2" "$1"
  grep -qF -- "$3" "$1" || { echo "PATCH FAILED: $1 :: $3"; exit 1; }
}

echo "== app name"
for f in ./Cargo.toml ./libs/portable/Cargo.toml; do
  sed -i -e "s|description = \"RustDesk Remote Desktop\"|description = \"$APP_NAME\"|" \
         -e "s|ProductName = \"RustDesk\"|ProductName = \"$APP_NAME\"|" \
         -e "s|FileDescription = \"RustDesk Remote Desktop\"|FileDescription = \"$APP_NAME\"|" \
         -e "s|OriginalFilename = \"rustdesk.exe\"|OriginalFilename = \"$APP_NAME.exe\"|" "$f"
  grep -qF "ProductName = \"$APP_NAME\"" "$f" || { echo "PATCH FAILED: $f"; exit 1; }
done
rep ./libs/portable/src/main.rs "s|const APP_PREFIX: \&str = \"rustdesk\";|const APP_PREFIX: \&str = \"into-remote\";|" 'APP_PREFIX: &str = "into-remote"'
sed -i -e "s|\"RustDesk Remote Desktop\"|\"$APP_NAME\"|" \
       -e "s|VALUE \"InternalName\", \"rustdesk\" \"\\0\"|VALUE \"InternalName\", \"$APP_NAME\" \"\\0\"|" \
       -e "s|\"rustdesk.exe\"|\"$APP_NAME.exe\"|" \
       -e "s|\"RustDesk\"|\"$APP_NAME\"|" ./flutter/windows/runner/Runner.rc
grep -qF "\"$APP_NAME\"" ./flutter/windows/runner/Runner.rc || { echo "PATCH FAILED: Runner.rc"; exit 1; }
rep ./libs/hbb_common/src/config.rs "s|RwLock::new(\"RustDesk\".to_owned())|RwLock::new(\"$APP_NAME\".to_owned())|" "RwLock::new(\"$APP_NAME\".to_owned())"
find ./src/lang -name "*.rs" -exec sed -i -e "s|RustDesk|$APP_NAME|g" {} \;

echo "== registry commands must survive a space in the app name"
"${PYTHON:-python3}" "$HERE/patch_registry.py"

echo "== publisher (upstream copyright notices stay untouched)"
rep ./flutter/windows/runner/Runner.rc "s|VALUE \"CompanyName\", \"Purslane Tech Pte. Ltd.\"|VALUE \"CompanyName\", \"$COMPANY\"|" "\"CompanyName\", \"$COMPANY\""
rep ./res/msi/preprocess.py "s|default=\"Purslane Tech Pte. Ltd.\"|default=\"$COMPANY\"|" "default=\"$COMPANY\""
for f in ./Cargo.toml ./libs/portable/Cargo.toml; do
  sed -i -e "/^ProductName = \"$APP_NAME\"/a CompanyName = \"$COMPANY\"" "$f"
  grep -qF "CompanyName = \"$COMPANY\"" "$f" || { echo "PATCH FAILED: CompanyName in $f"; exit 1; }
done

echo "== INTO colours"
"${PYTHON:-python3}" "$HERE/patch_theme.py"

echo "== links"
sed -i -e "s|Homepage: https://rustdesk.com|Homepage: $HOMEPAGE|" ./build.py
sed -i -e "s|launchUrl(Uri.parse('https://rustdesk.com'));|launchUrl(Uri.parse('$HOMEPAGE'));|" ./flutter/lib/common.dart
sed -i -e "s|launchUrlString('https://rustdesk.com');|launchUrlString('$HOMEPAGE');|" \
       -e "s|launchUrlString('https://rustdesk.com/privacy.html')|launchUrlString('$HOMEPAGE/privacy/')|" ./flutter/lib/desktop/pages/desktop_setting_page.dart
sed -i -e "s|https://rustdesk.com/privacy.html|$HOMEPAGE/privacy/|" ./flutter/lib/desktop/pages/install_page.dart
sed -i -e "s|https://rustdesk.com/download|$DOWNLOAD_URL|" ./flutter/lib/desktop/pages/desktop_home_page.dart ./src/ui/index.tis

echo "== our server is compiled in"
C=./libs/hbb_common/src/config.rs
rep "$C" "s|rs-ny.rustdesk.com|$SERVER_HOST|" "$SERVER_HOST"
rep "$C" "s|OeVuKk5nlHiXp+APNn0Y3pC1Iwpwn44JGqrQCsWqmBw=|$SERVER_KEY|" "$SERVER_KEY"
sed -i -e "s|            if (!isIncomingOnly) setupServerWidget(),|            //if (!isIncomingOnly) setupServerWidget(),|" ./flutter/lib/desktop/pages/connection_page.dart

echo "== no update prompts pointing at upstream binaries"
rep ./flutter/lib/desktop/pages/desktop_home_page.dart "s|updateUrl.isNotEmpty \&\&|false \&\&|" "false &&"
"${PYTHON:-python3}" - <<'PY'
import re,io
p='src/common.rs'; s=io.open(p,encoding='utf-8').read()
a='pub async fn do_check_software_update() -> hbb_common::ResultType<()> {\n'
assert a in s, 'update fn not found'
s=s.replace(a, a+'    if true {\n        return Ok(());\n    }\n',1)
# unsigned custom client config, read from custom_.txt (we build from source, there is no vendor signature)
m=re.search(r'    const KEY: &str = "5Qbwsde3unUcJBtrx9ZkvUmwFNoExHzpryHuPUdqlWM=";\n.*?    let Ok\(data\) = sign::verify\(&data, &pk\) else \{\n.*?\n    \};\n', s, re.S)
assert m, 'custom client signature block not found'
s=s[:m.start()]+s[m.end():]
assert s.count('custom.txt')>=2
s=s.replace('custom.txt','custom_.txt')
io.open(p,'w',encoding='utf-8',newline='\n').write(s)
print('common.rs patched')
PY

echo "== icons"
cp "$HERE/icon.png" ./res/icon.png
cp "$HERE/icon.ico" ./res/icon.ico
cp "$HERE/icon.ico" ./res/tray-icon.ico
cp "$HERE/icon.ico" ./flutter/windows/runner/resources/app_icon.ico
cp "$HERE/icon.svg" ./flutter/assets/icon.svg
for s in 32 64 128; do cp "$HERE/png/${s}x${s}.png" "./res/${s}x${s}.png"; done
cp "$HERE/png/128x128@2x.png" "./res/128x128@2x.png"
b64=$(base64 -w0 < "$HERE/png/128x128.png")
B64="$b64" perl -0777 -pe 's|iVBORw0KGgoAAAANSUhEUgAAAIAAAACACAYAAADDPmHL[A-Za-z0-9+/=]+|$ENV{B64}|g' -i ./src/ui.rs

echo "INTO Remote branding applied on RustDesk $RUSTDESK_VERSION"
