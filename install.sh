#!/bin/bash
# install.sh - Installa il widget Plasma "Messier & Caldwell Visible Objects"

WIDGET_ID="org.kde.plasma.messier_caldwell"
WIDGET_DIR="$HOME/.local/share/plasma/plasmoids/$WIDGET_ID"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Messier & Caldwell Visible Objects — Plasma Widget ==="
echo ""

if ! command -v plasmashell &>/dev/null; then
    echo "[WARNING] plasmashell not found. Make sure you are running KDE Plasma."
fi

# Rimuovi versione precedente
if [ -d "$WIDGET_DIR" ]; then
    echo "[INFO] Removing previous version..."
    rm -rf "$WIDGET_DIR"
fi

# Copia file widget
echo "[INFO] Installing to $WIDGET_DIR ..."
mkdir -p "$WIDGET_DIR"
cp -r "$SCRIPT_DIR/contents"      "$WIDGET_DIR/"
cp -r "$SCRIPT_DIR/config"        "$WIDGET_DIR/"
cp    "$SCRIPT_DIR/metadata.json" "$WIDGET_DIR/"

echo "[OK] Widget files copied."

# Installa i file .mo in ~/.local/share/locale/<lang>/LC_MESSAGES/
# Plasma li cerca qui per i plasmoid installati localmente
echo "[INFO] Installing translations..."
for lang in it en; do
    MO_SRC="$SCRIPT_DIR/contents/locale/$lang/LC_MESSAGES/plasma_${WIDGET_ID}.mo"
    MO_DST="$HOME/.local/share/locale/$lang/LC_MESSAGES"
    if [ -f "$MO_SRC" ]; then
        mkdir -p "$MO_DST"
        cp "$MO_SRC" "$MO_DST/"
        echo "[OK] Translation installed: $lang"
    fi
done

# Ricarica Plasma
if command -v plasmashell &>/dev/null; then
    echo "[INFO] Reloading plasmoids..."
    kquitapp6 plasmashell 2>/dev/null || kquitapp5 plasmashell 2>/dev/null || true
    sleep 1
    nohup plasmashell &>/dev/null &
    echo "[OK] Plasma restarted."
    echo ""
    echo "      Right-click desktop → Add Widgets → search 'Messier'"
fi

echo ""
echo "=== Installation complete ==="
