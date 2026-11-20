# Copyright (C) 2026 Muertazos Racing
# Licensed under AGPL-3.0 (or later), see <https://www.gnu.org/licenses/>.
# SPDX-License-Identifier: AGPL-3.0-or-later
#
# Funciones comunes para leer tools/allowlist.txt. Se usa con "source"; no se ejecuta.
# shellcheck shell=bash

ALLOW_PATTERNS=()

# load_allowlist <archivo>: rellena ALLOW_PATTERNS; falla si no existe o queda vacia.
load_allowlist() {
  local file="$1" line
  if [ ! -f "$file" ]; then
    echo "FALLO [allowlist]: no existe $file" >&2
    return 1
  fi
  ALLOW_PATTERNS=()
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line//$'\r'/}"
    line="${line%%#*}"
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    if [ -n "$line" ]; then
      ALLOW_PATTERNS+=("$line")
    fi
  done < "$file"
  if [ "${#ALLOW_PATTERNS[@]}" -eq 0 ]; then
    echo "FALLO [allowlist]: $file no contiene ningun patron" >&2
    return 1
  fi
}

# is_allowed <ruta>: 0 si la ruta casa con algun patron de ALLOW_PATTERNS.
is_allowed() {
  local path="$1" pattern
  for pattern in "${ALLOW_PATTERNS[@]}"; do
    # shellcheck disable=SC2053  # el patron sin comillas es intencional (glob)
    if [[ "$path" == $pattern ]]; then
      return 0
    fi
  done
  return 1
}
