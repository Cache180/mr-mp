#!/usr/bin/env bash
# Copyright (C) 2026 Muertazos Racing
# Licensed under AGPL-3.0 (or later), see <https://www.gnu.org/licenses/>.
# SPDX-License-Identifier: AGPL-3.0-or-later
#
# Guardian: cada .json cambiado respecto a la base upstream es JSON valido.
# Uso: tools/check_json.sh [<base-sha>]     (el CI pasa el contenido de tools/base-sha.txt, como check_touched)
# Detalle de reglas en tools/check_json.js. Requiere node.
# Exit: 0 limpio | 1 violacion o herramienta ausente
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! command -v node >/dev/null 2>&1; then
  echo "FALLO [check_json]: node no esta instalado; no se puede dar un resultado fiable." >&2
  exit 1
fi
exec node "$ROOT/tools/check_json.js" "$@"
