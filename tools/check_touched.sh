#!/usr/bin/env bash
# Copyright (C) 2026 Muertazos Racing
# Licensed under AGPL-3.0 (or later), see <https://www.gnu.org/licenses/>.
# SPDX-License-Identifier: AGPL-3.0-or-later
#
# Guardian "solo lista blanca": falla si HEAD difiere de la base upstream en
# algun archivo (modificado, anadido o borrado) que no case con tools/allowlist.txt.
# Uso: tools/check_touched.sh <base-sha>      (el CI pasa el contenido de tools/base-sha.txt)
# Exit: 0 limpio | 1 violacion o base inalcanzable | 2 error de uso
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
# shellcheck source=tools/allowlist_lib.sh
source "$ROOT/tools/allowlist_lib.sh"

if [ "$#" -ne 1 ]; then
  echo "uso: tools/check_touched.sh <base-sha>" >&2
  exit 2
fi
base="$1"
if ! [[ "$base" =~ ^[0-9a-f]{40}$ ]]; then
  echo "FALLO [check_touched]: la base debe ser un sha completo de 40 hex, recibido: '$base'" >&2
  exit 2
fi

if ! git cat-file -e "${base}^{commit}" 2>/dev/null; then
  echo "FALLO [check_touched]: el commit base $base no esta en este checkout." >&2
  echo "  Checkout superficial? Usa 'fetch-depth: 0'. No se puede dar un resultado fiable." >&2
  exit 1
fi
if ! git merge-base --is-ancestor "$base" HEAD; then
  echo "FALLO [check_touched]: $base no es ancestro de HEAD; el diff no tendria sentido." >&2
  exit 1
fi

load_allowlist tools/allowlist.txt

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
# --no-renames: un renombrado aparece como borrado + alta y se comprueban ambas rutas.
git diff --name-only --no-renames -z "$base" HEAD > "$tmp"

total=0
violations=0
while IFS= read -r -d '' file; do
  total=$((total + 1))
  if ! is_allowed "$file"; then
    echo "FALLO [check_touched]: archivo fuera de la lista blanca (tools/allowlist.txt): $file" >&2
    violations=$((violations + 1))
  fi
done < "$tmp"

if [ "$violations" -ne 0 ]; then
  echo "check_touched: $violations de $total archivos cambiados respecto a $base estan fuera de la lista blanca." >&2
  exit 1
fi
echo "check_touched OK: $total archivos cambiados respecto a $base, todos en la lista blanca."
