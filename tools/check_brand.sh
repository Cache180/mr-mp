#!/usr/bin/env bash
# Copyright (C) 2026 Muertazos Racing
# Licensed under AGPL-3.0 (or later), see <https://www.gnu.org/licenses/>.
# SPDX-License-Identifier: AGPL-3.0-or-later
#
# Guardian de marca: falla si alguna cadena VISIBLE (valores de locales, texto de plantillas .vue/.html,
# name/description de los app.json, titulo de uilayout, literales de script con frases) dice BeamMP o apunta
# a servicios de BeamMP (beammp.com, patreon, forum.beammp...), salvo el bloque del aviso de licencia de
# ui/ui-vue/mods/BeamMP/views/BeamMPTOSView.vue. Detalle de reglas en tools/check_brand.js.
# Requiere node y @vue/compiler-sfc (MR_SFC_DIR apunta a la carpeta donde se instalo; el CI lo instala).
# Exit: 0 limpio | 1 violacion o herramienta ausente
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! command -v node >/dev/null 2>&1; then
  echo "FALLO [check_brand]: node no esta instalado; no se puede dar un resultado fiable." >&2
  exit 1
fi
exec node "$ROOT/tools/check_brand.js" "$@"
