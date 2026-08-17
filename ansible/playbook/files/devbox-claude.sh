#!/bin/bash
# Lanzador de Claude Code: pregunta el directorio de trabajo y abre una terminal
# ya parada ahi. Sin argumentos arranca en el ultimo usado, o en $HOME.
set -euo pipefail

STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/devbox"
LAST_DIR_FILE="$STATE_DIR/claude-last-dir"
mkdir -p "$STATE_DIR"

start_dir="$HOME"
if [[ -r "$LAST_DIR_FILE" ]]; then
    saved="$(cat "$LAST_DIR_FILE")"
    [[ -d "$saved" ]] && start_dir="$saved"
fi

# zenity devuelve != 0 si cancelas: en ese caso no abrimos nada.
work_dir="$(zenity --file-selection --directory \
    --title="Claude Code: elegi el directorio de trabajo" \
    --filename="$start_dir/" 2>/dev/null)" || exit 0

[[ -d "$work_dir" ]] || exit 0
printf '%s\n' "$work_dir" > "$LAST_DIR_FILE"

# `exec bash` al final deja la terminal abierta cuando Claude Code termina, para
# poder leer lo ultimo que imprimio.
exec xfce4-terminal \
    --working-directory="$work_dir" \
    --title="Claude Code - $(basename "$work_dir")" \
    -x bash -lc 'claude; exec bash'
