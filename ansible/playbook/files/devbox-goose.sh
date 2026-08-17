#!/bin/bash
# Lanzador de goose: abre una sesion en una terminal.
set -euo pipefail

# goose se instala en ~/.local/bin, que no siempre esta en el PATH del lanzador.
GOOSE="$HOME/.local/bin/goose"
[[ -x "$GOOSE" ]] || GOOSE="$(command -v goose || true)"

if [[ -z "$GOOSE" ]]; then
    zenity --error --text="No encuentro el binario de goose." 2>/dev/null || true
    exit 1
fi

exec xfce4-terminal --title="goose" -x bash -lc "'$GOOSE' session; exec bash"
