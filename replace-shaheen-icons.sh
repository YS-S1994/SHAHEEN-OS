#!/data/data/com.termux/files/usr/bin/bash

set -u

PROJECT="$(pwd)"
RES="$PROJECT/app/src/main/res"
SOURCE="$RES/drawable/shaheen.jpg"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$PROJECT/.shaheen-icon-backup-$STAMP"

echo
echo "============================================================"
echo "        SHAHEEN-OS — LAUNCHER ICON REPLACEMENT"
echo "============================================================"
echo
echo "Project : $PROJECT"
echo "Source  : $SOURCE"
echo "Backup  : $BACKUP"
echo

# ------------------------------------------------------------
# 1. Verify project
# ------------------------------------------------------------

if [ ! -d "$RES" ]; then
    echo "[ERROR] Android resources directory not found:"
    echo "$RES"
    exit 1
fi

if [ ! -f "$SOURCE" ]; then
    echo "[ERROR] New icon not found:"
    echo "$SOURCE"
    echo
    echo "Expected:"
    echo "app/src/main/res/drawable/shaheen.jpg"
    exit 1
fi

# ------------------------------------------------------------
# 2. Create backup
# ------------------------------------------------------------

echo "[1/7] Creating backup..."

mkdir -p "$BACKUP"

for d in \
    mipmap-mdpi \
    mipmap-hdpi \
    mipmap-xhdpi \
    mipmap-xxhdpi \
    mipmap-xxxhdpi \
    mipmap-anydpi-v26 \
    drawable
do
    if [ -d "$RES/$d" ]; then
        mkdir -p "$BACKUP/$d"

        for f in \
            ic_launcher.png \
            ic_launcher_round.png \
            ic_launcher.xml \
            ic_launcher_round.xml \
            ic_launcher_foreground.xml \
            ic_launcher_background.xml \
            ic_launcher_monochrome.xml
        do
            if [ -f "$RES/$d/$f" ]; then
                cp -p "$RES/$d/$f" "$BACKUP/$d/$f"
            fi
        done
    fi
done

echo "[OK] Backup created:"
echo "$BACKUP"
echo

# ------------------------------------------------------------
# 3. Detect image processor
# ------------------------------------------------------------

echo "[2/7] Detecting image processor..."

IMG_TOOL=""

if command -v magick >/dev/null 2>&1; then
    IMG_TOOL="magick"
elif command -v convert >/dev/null 2>&1; then
    IMG_TOOL="convert"
fi

if [ -n "$IMG_TOOL" ]; then
    echo "[OK] ImageMagick detected: $IMG_TOOL"
else
    echo "[INFO] ImageMagick not found."
fi

# ------------------------------------------------------------
# 4. Python/Pillow fallback
# ------------------------------------------------------------

PYTHON_OK="0"

if [ -z "$IMG_TOOL" ]; then
    if command -v python >/dev/null 2>&1; then
        if python -c 'from PIL import Image' >/dev/null 2>&1; then
            PYTHON_OK="1"
            echo "[OK] Python + Pillow detected."
        fi
    fi

    if [ "$PYTHON_OK" = "0" ] && command -v python3 >/dev/null 2>&1; then
        if python3 -c 'from PIL import Image' >/dev/null 2>&1; then
            PYTHON_OK="1"
            echo "[OK] Python3 + Pillow detected."
        fi
    fi
fi

# ------------------------------------------------------------
# 5. Install ImageMagick in Termux if necessary
# ------------------------------------------------------------

if [ -z "$IMG_TOOL" ] && [ "$PYTHON_OK" = "0" ]; then

    echo
    echo "[INFO] No image conversion tool is available."
    echo "[INFO] Trying to install ImageMagick in Termux..."
    echo

    if command -v pkg >/dev/null 2>&1; then
        pkg install -y imagemagick

        if command -v magick >/dev/null 2>&1; then
            IMG_TOOL="magick"
        elif command -v convert >/dev/null 2>&1; then
            IMG_TOOL="convert"
        fi
    fi
fi

if [ -z "$IMG_TOOL" ] && [ "$PYTHON_OK" = "0" ]; then
    echo
    echo "[ERROR] No image processing tool is available."
    echo
    echo "Install ImageMagick manually with:"
    echo
    echo "pkg install imagemagick"
    echo
    echo "Then run this script again."
    exit 1
fi

# ------------------------------------------------------------
# 6. Generate Android launcher icons
# ------------------------------------------------------------

echo "[3/7] Generating launcher icons..."
echo

generate_icon() {
    SRC="$1"
    OUT="$2"
    SIZE="$3"

    mkdir -p "$(dirname "$OUT")"

    if [ "$IMG_TOOL" = "magick" ]; then
        magick "$SRC" \
            -auto-orient \
            -resize "${SIZE}x${SIZE}^" \
            -gravity center \
            -extent "${SIZE}x${SIZE}" \
            -strip \
            -define png:compression-level=9 \
            PNG32:"$OUT"

    elif [ "$IMG_TOOL" = "convert" ]; then
        convert "$SRC" \
            -auto-orient \
            -resize "${SIZE}x${SIZE}^" \
            -gravity center \
            -extent "${SIZE}x${SIZE}" \
            -strip \
            -define png:compression-level=9 \
            PNG32:"$OUT"

    else
        python - "$SRC" "$OUT" "$SIZE" <<'PY'
import sys
from PIL import Image

src = sys.argv[1]
out = sys.argv[2]
size = int(sys.argv[3])

img = Image.open(src).convert("RGBA")
img.thumbnail((size, size), Image.Resampling.LANCZOS)

canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))

x = (size - img.width) // 2
y = (size - img.height) // 2

canvas.alpha_composite(img, (x, y))
canvas.save(out, "PNG", optimize=True)
PY
    fi
}

# Android legacy launcher sizes
generate_icon "$SOURCE" "$RES/mipmap-mdpi/ic_launcher.png"       48
generate_icon "$SOURCE" "$RES/mipmap-hdpi/ic_launcher.png"       72
generate_icon "$SOURCE" "$RES/mipmap-xhdpi/ic_launcher.png"     96
generate_icon "$SOURCE" "$RES/mipmap-xxhdpi/ic_launcher.png"   144
generate_icon "$SOURCE" "$RES/mipmap-xxxhdpi/ic_launcher.png"  192

# Round icons
generate_icon "$SOURCE" "$RES/mipmap-mdpi/ic_launcher_round.png"       48
generate_icon "$SOURCE" "$RES/mipmap-hdpi/ic_launcher_round.png"       72
generate_icon "$SOURCE" "$RES/mipmap-xhdpi/ic_launcher_round.png"     96
generate_icon "$SOURCE" "$RES/mipmap-xxhdpi/ic_launcher_round.png"   144
generate_icon "$SOURCE" "$RES/mipmap-xxxhdpi/ic_launcher_round.png"  192

echo "[OK] Legacy launcher icons replaced."
echo

# ------------------------------------------------------------
# 7. Create adaptive launcher foreground
# ------------------------------------------------------------

echo "[4/7] Creating adaptive launcher foreground..."

ADAPTIVE="$RES/drawable/shaheen_launcher_foreground.png"

generate_icon "$SOURCE" "$ADAPTIVE" 432

echo "[OK] $ADAPTIVE"
echo

# ------------------------------------------------------------
# 8. Replace adaptive icon XML
# ------------------------------------------------------------

echo "[5/7] Updating adaptive launcher XML..."

cat > "$RES/mipmap-anydpi-v26/ic_launcher.xml" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/shaheen_launcher_background"/>
    <foreground android:drawable="@drawable/shaheen_launcher_foreground"/>
</adaptive-icon>
EOF

cat > "$RES/mipmap-anydpi-v26/ic_launcher_round.xml" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/shaheen_launcher_background"/>
    <foreground android:drawable="@drawable/shaheen_launcher_foreground"/>
</adaptive-icon>
EOF

echo "[OK] Adaptive launcher XML updated."
echo

# ------------------------------------------------------------
# 9. Create SHAHEEN launcher background
# ------------------------------------------------------------

echo "[6/7] Creating launcher background resource..."

mkdir -p "$RES/values"

cat > "$RES/values/shaheen_launcher_colors.xml" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="shaheen_launcher_background">#000000</color>
</resources>
EOF

echo "[OK] Background resource created."
echo

# ------------------------------------------------------------
# 10. Verification
# ------------------------------------------------------------

echo "[7/7] Verifying new launcher icons..."
echo

echo "===== SOURCE ====="
ls -lh "$SOURCE"

echo
echo "===== GENERATED ICONS ====="

find "$RES" -type f \( \
    -path "*/mipmap-mdpi/ic_launcher.png" -o \
    -path "*/mipmap-hdpi/ic_launcher.png" -o \
    -path "*/mipmap-xhdpi/ic_launcher.png" -o \
    -path "*/mipmap-xxhdpi/ic_launcher.png" -o \
    -path "*/mipmap-xxxhdpi/ic_launcher.png" -o \
    -path "*/mipmap-mdpi/ic_launcher_round.png" -o \
    -path "*/mipmap-hdpi/ic_launcher_round.png" -o \
    -path "*/mipmap-xhdpi/ic_launcher_round.png" -o \
    -path "*/mipmap-xxhdpi/ic_launcher_round.png" -o \
    -path "*/mipmap-xxxhdpi/ic_launcher_round.png" -o \
    -path "*/drawable/shaheen_launcher_foreground.png" \
\) -exec ls -lh {} \;

echo
echo "===== ADAPTIVE ICONS ====="

cat "$RES/mipmap-anydpi-v26/ic_launcher.xml"
echo
cat "$RES/mipmap-anydpi-v26/ic_launcher_round.xml"

echo
echo "============================================================"
echo "                  COMPLETED SUCCESSFULLY"
echo "============================================================"
echo
echo "New launcher image:"
echo "  $SOURCE"
echo
echo "Backup:"
echo "  $BACKUP"
echo
echo "The old launcher icons were replaced."
echo "Other application icons were NOT modified."
echo
