#!/usr/bin/env bash
# Copyright (C) 2026 Muertazos Racing
# Licensed under AGPL-3.0 (or later), see <https://www.gnu.org/licenses/>.
# SPDX-License-Identifier: AGPL-3.0-or-later
#
# Guardian de aceptacion de licencia (HEURISTICO, no es un analizador de JS). En ui/ui-vue/mods/BeamMP/:
#   Regla 1: no debe aparecer el token suelto "tosAccepted" (la clave de aceptacion de BeamMP, sin prefijo
#            mr) en NINGUN archivo. Se caza el token este o no junto a localStorage, por lo que tambien falla
#            con alias (const K="tosAccepted"), template literals, window["localStorage"], acceso por
#            corchetes y usos partidos en dos lineas (la cadena "tosAccepted" sigue en una linea). La clave
#            propia mrTosAccepted (con T mayuscula) NO contiene el token "tosAccepted" en minuscula, asi que
#            no da falso positivo.
#   Regla 2: beammpState.js debe USAR la clave propia (mrTosAccepted), no solo evitar la vieja.
#   Regla 3: la barra lateral (BeamMPMain.vue) debe llevar el enlace permanente al codigo fuente dentro de un
#            <a href="...Cache180/mr-mp..."> o como llamada openExternal('...Cache180/mr-mp'). Una simple
#            mencion en un comentario con la URL suelta NO basta.
# QUE NO CAZA (es heuristica): reconstruir el token "tosAccepted" por concatenacion de cadenas u ofuscaciones
#   similares; ni comprueba en tiempo de ejecucion que @click llama de verdad a openExternal.
# Falla cerrado: si faltan los archivos o el arbol del mod, o si la autoprueba del detector falla.
# Exit: 0 limpio | 1 violacion, archivo/arbol ausente o autoprueba fallida
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

DIR="ui/ui-vue/mods/BeamMP"
STATE="$DIR/shared/beammpState.js"
MAIN="$DIR/layouts/BeamMPMain.vue"
URL="https://github.com/Cache180/mr-mp"
# Token suelto "tosAccepted": no precedido ni seguido de caracter de identificador. Distingue de
# mrTosAccepted (T mayuscula) y de tosAcceptedFoo. Sensible a mayusculas (grep -E sin -i).
TOKEN_RE='(^|[^A-Za-z0-9_])tosAccepted([^A-Za-z0-9_]|$)'

fails=0
checked=0
bad() { printf 'FALLO [check_tos]: %s\n' "$1" >&2; fails=$((fails + 1)); }

# --- Autoprueba del detector (fixtures negativos; prueba que caza cada forma de evasion) ---
selftest() {
  local s
  local -a BADS=(
    'localStorage.getItem("tosAccepted")'
    'const K="tosAccepted"; localStorage.getItem(K)'
    'const K=`tosAccepted`'
    'window["localStorage"].getItem("tosAccepted")'
    'localStorage["getItem"]("tosAccepted")'
    '  "tosAccepted")'
  )
  for s in "${BADS[@]}"; do
    if ! printf '%s\n' "$s" | grep -qE "$TOKEN_RE"; then
      echo "FALLO [check_tos:selftest]: el detector no caza una evasion conocida: $s" >&2
      return 1
    fi
  done
  local -a GOODS=(
    'mrTosAccepted: ref(localStorage.getItem("mrTosAccepted") === "true"),'
    'state.mrTosAccepted.value = true'
  )
  for s in "${GOODS[@]}"; do
    if printf '%s\n' "$s" | grep -qE "$TOKEN_RE"; then
      echo "FALLO [check_tos:selftest]: falso positivo del detector con la clave propia: $s" >&2
      return 1
    fi
  done
  return 0
}

if ! selftest; then
  echo "check_tos: autoprueba del detector fallida; el guardian no es fiable." >&2
  exit 1
fi

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
git ls-files -z -- "$DIR" > "$tmp"
if [ ! -s "$tmp" ]; then
  echo "FALLO [check_tos]: no hay archivos versionados en $DIR (no se puede dar un resultado fiable)" >&2
  exit 1
fi

# Regla 1: token suelto tosAccepted en cualquier archivo del mod.
while IFS= read -r -d '' file; do
  [ -f "$file" ] || continue
  checked=$((checked + 1))
  hits="$(grep -nE "$TOKEN_RE" "$file" | cut -c1-160 || true)"
  if [ -n "$hits" ]; then
    bad "token 'tosAccepted' (clave de BeamMP, sin prefijo mr) en $file"
    printf '         %s\n' "$hits" >&2
  fi
done < "$tmp"

# Regla 2: beammpState.js usa la clave propia.
checked=$((checked + 1))
if [ ! -f "$STATE" ]; then
  bad "no existe $STATE (no se puede comprobar el uso de mrTosAccepted)"
elif ! grep -qF -- "mrTosAccepted" "$STATE"; then
  bad "falta el uso de la clave propia 'mrTosAccepted' en $STATE"
fi

# Regla 3: enlace permanente en un <a href="...mr-mp..."> o como openExternal('...mr-mp').
checked=$((checked + 1))
if [ ! -f "$MAIN" ]; then
  bad "no existe $MAIN (no se puede comprobar el enlace al codigo fuente)"
elif ! grep -qF -- "openExternal('$URL')" "$MAIN" \
     && ! { grep -qE '<a([[:space:]]|>)' "$MAIN" && grep -qF -- "href=\"$URL\"" "$MAIN"; }; then
  bad "falta el enlace permanente al codigo fuente en $MAIN (como openExternal('$URL') o <a href=\"$URL\">)"
fi

if [ "$fails" -ne 0 ]; then
  echo "check_tos: $fails de $checked comprobaciones fallaron." >&2
  exit 1
fi
echo "check_tos OK: $checked comprobaciones (autoprueba del detector incluida)."
