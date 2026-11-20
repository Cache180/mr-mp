#!/usr/bin/env bash
# Copyright (C) 2026 Muertazos Racing
# Licensed under AGPL-3.0 (or later), see <https://www.gnu.org/licenses/>.
# SPDX-License-Identifier: AGPL-3.0-or-later
#
# Guardian de identidad: el mod debe llamarse multiplayermrmp (zip MRMP.zip) y hablar con
# el launcher por el puerto 4464 (ajuste mrLauncherPort). Falla si queda el nombre/puerto
# de upstream, o si faltan los valores nuevos (para no pasar en vacio).
# Exit: 0 limpio | 1 violacion o archivo ausente
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

MODSCRIPT="scripts/BeamMP/modScript.lua"
MODMGR="lua/ge/extensions/MPModManager.lua"
CORENET="lua/ge/extensions/MPCoreNetwork.lua"
GAMENET="lua/ge/extensions/MPGameNetwork.lua"
CONFIG="lua/ge/extensions/MPConfig.lua"
DEFAULTS="settings/mp_defaults.json"
LAYOUT="ui/ui-vue/src/modules/options/runtime/layout.json"

fails=0
checked=0
bad() { printf 'FALLO [check_names]: %s\n' "$1" >&2; fails=$((fails + 1)); }

for f in "$MODSCRIPT" "$MODMGR" "$CORENET" "$GAMENET" "$CONFIG" "$DEFAULTS" "$LAYOUT"; do
  if [ ! -f "$f" ]; then
    echo "FALLO [check_names]: no existe $f (no se puede dar un resultado fiable)" >&2
    exit 1
  fi
done

# absent <archivo> <texto> <regla>: el texto fijo NO debe aparecer.
absent() {
  local hits
  checked=$((checked + 1))
  hits="$(grep -nF -- "$2" "$1" | cut -c1-160 || true)"
  if [ -n "$hits" ]; then
    bad "$3: '$2' sigue en $1"
    printf '         %s\n' "$hits" >&2
  fi
}
# present <archivo> <texto> <regla>: el texto fijo DEBE aparecer.
present() {
  checked=$((checked + 1))
  if ! grep -qF -- "$2" "$1"; then
    bad "$3: falta '$2' en $1"
  fi
}

# Nombre de mod
absent  "$MODSCRIPT" "multiplayerbeammp" "nombre de mod upstream"
absent  "$MODMGR"    "multiplayerbeammp" "nombre de mod upstream"
present "$MODSCRIPT" "deactivateMod('multiplayermrmp')" "nombre de mod MR"
present "$MODSCRIPT" "deactivateMod('mrmp')" "nombre de mod MR"
absent  "$MODSCRIPT" "deactivateMod('beammp')" "identificador de mod upstream"
present "$MODMGR"    'local whitelist = {"multiplayermrmp", "mrmp", "translations"}' "lista blanca de mods"
present "$MODMGR"    'modname ~= "multiplayermrmp"' "excepcion de cleanUpSessionMods"

# Aviso de version incompatible
absent  "$MODSCRIPT" "Error loading BeamMP" "titulo del aviso upstream"
present "$MODSCRIPT" "Error al cargar MR Multiplayer" "titulo del aviso MR"
present "$MODSCRIPT" "MR Multiplayer aun no es compatible con BeamNG.drive" "aviso de version nueva"
present "$MODSCRIPT" "MR Multiplayer no es compatible con BeamNG.drive" "aviso de version vieja"

# Puerto del launcher
for f in "$CORENET" "$GAMENET"; do
  absent  "$f" "4444" "puerto por defecto upstream"
  present "$f" "mrLauncherPort" "ajuste del puerto MR"
  present "$f" "4464" "puerto por defecto MR"
done
for f in "$CONFIG" "$DEFAULTS"; do
  absent  "$f" "4444" "puerto por defecto upstream"
  present "$f" "mrLauncherPort" "ajuste del puerto MR"
done
absent  "$LAYOUT" '"setting": "launcherPort"' "campo de puerto del menu apunta al ajuste upstream"
present "$LAYOUT" '"setting": "mrLauncherPort"' "campo de puerto del menu"

if [ "$fails" -ne 0 ]; then
  echo "check_names: $fails de $checked comprobaciones fallaron." >&2
  exit 1
fi
echo "check_names OK: $checked comprobaciones."
