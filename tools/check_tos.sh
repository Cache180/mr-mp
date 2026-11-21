#!/usr/bin/env bash
# Copyright (C) 2026 Muertazos Racing
# Licensed under AGPL-3.0 (or later), see <https://www.gnu.org/licenses/>.
# SPDX-License-Identifier: AGPL-3.0-or-later
#
# Guardian de aceptacion de licencia: la aceptacion del mod se guarda bajo una clave propia de
# localStorage ("mrTosAccepted"); la clave de BeamMP ("tosAccepted", sin prefijo mr) no debe
# consultarse. Ademas, la barra lateral (BeamMPMain.vue) debe llevar el enlace permanente al
# codigo fuente y licencia. Falla cerrado si no hay archivos del mod o falta la vista a comprobar.
# Exit: 0 limpio | 1 violacion o archivo/arbol ausente
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

DIR="ui/ui-vue/mods/BeamMP"
MAIN="$DIR/layouts/BeamMPMain.vue"
LINK="https://github.com/Cache180/mr-mp"
# Clave de aceptacion de BeamMP (sin prefijo mr). La propia del mod es mrTosAccepted (T mayuscula),
# que no casa con este patron ni por prefijo ni por mayusculas.
LEGACY_RE="localStorage[^\"']*[\"']tosAccepted[\"']"

fails=0
checked=0
bad() { printf 'FALLO [check_tos]: %s\n' "$1" >&2; fails=$((fails + 1)); }

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
git ls-files -z -- "$DIR" > "$tmp"
if [ ! -s "$tmp" ]; then
  echo "FALLO [check_tos]: no hay archivos versionados en $DIR (no se puede dar un resultado fiable)" >&2
  exit 1
fi

# Regla 1: ningun archivo del mod consulta localStorage con la clave tosAccepted (sin prefijo mr).
while IFS= read -r -d '' file; do
  [ -f "$file" ] || continue
  checked=$((checked + 1))
  hits="$(grep -nE "$LEGACY_RE" "$file" | cut -c1-160 || true)"
  if [ -n "$hits" ]; then
    bad "clave de aceptacion de BeamMP ('tosAccepted', sin prefijo mr) en localStorage de $file"
    printf '         %s\n' "$hits" >&2
  fi
done < "$tmp"

# Regla 2: la barra lateral lleva el enlace permanente al codigo fuente y licencia.
checked=$((checked + 1))
if [ ! -f "$MAIN" ]; then
  bad "no existe $MAIN (no se puede comprobar el enlace al codigo fuente)"
elif ! grep -qF -- "$LINK" "$MAIN"; then
  bad "falta el enlace permanente al codigo fuente y licencia ('$LINK') en $MAIN"
fi

if [ "$fails" -ne 0 ]; then
  echo "check_tos: $fails de $checked comprobaciones fallaron." >&2
  exit 1
fi
echo "check_tos OK: $checked comprobaciones."
