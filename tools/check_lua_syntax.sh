#!/usr/bin/env bash
# Copyright (C) 2026 Muertazos Racing
# Licensed under AGPL-3.0 (or later), see <https://www.gnu.org/licenses/>.
# SPDX-License-Identifier: AGPL-3.0-or-later
#
# Guardian de sintaxis: analiza todos los .lua versionados que case tools/allowlist.txt
# (los unicos que podemos haber tocado). El juego usa LuaJIT, por eso el analizador
# preferido es `luajit -bl`; alternativa: `luac5.1 -p`. Un error de sintaxis en modScript.lua
# impediria que el mod cargue por completo y no hay prueba en el juego en el CI.
# Exit: 0 todos validos | 1 error de sintaxis, sin analizador o nada que analizar
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
# shellcheck source=tools/allowlist_lib.sh
source "$ROOT/tools/allowlist_lib.sh"

if command -v luajit >/dev/null 2>&1; then
  parser_name="luajit"
  parse() { luajit -bl "$1" >/dev/null; }
elif command -v luac5.1 >/dev/null 2>&1; then
  parser_name="luac5.1"
  parse() { luac5.1 -p "$1"; }
else
  echo "FALLO [check_lua_syntax]: no hay analizador Lua (instala luajit o lua5.1)" >&2
  exit 1
fi

load_allowlist tools/allowlist.txt

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
git ls-files -z -- '*.lua' > "$tmp"

total=0
fails=0
saw_modscript=0
while IFS= read -r -d '' file; do
  is_allowed "$file" || continue
  [ -f "$file" ] || continue
  total=$((total + 1))
  [ "$file" = "scripts/BeamMP/modScript.lua" ] && saw_modscript=1
  if parse "$file"; then
    printf 'ok     %s\n' "$file"
  else
    echo "FALLO [check_lua_syntax]: error de sintaxis en $file" >&2
    fails=$((fails + 1))
  fi
done < "$tmp"

if [ "$total" -eq 0 ] || [ "$saw_modscript" -ne 1 ]; then
  echo "FALLO [check_lua_syntax]: no se analizo scripts/BeamMP/modScript.lua (lista blanca o arbol vacios?)" >&2
  exit 1
fi
if [ "$fails" -ne 0 ]; then
  echo "check_lua_syntax ($parser_name): $fails de $total archivos con error de sintaxis." >&2
  exit 1
fi
echo "check_lua_syntax OK ($parser_name): $total archivos .lua validos."
