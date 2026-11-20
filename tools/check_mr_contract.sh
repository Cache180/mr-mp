#!/usr/bin/env bash
# Copyright (C) 2026 Muertazos Racing
# Licensed under AGPL-3.0 (or later), see <https://www.gnu.org/licenses/>.
# SPDX-License-Identifier: AGPL-3.0-or-later
#
# Guardian de contrato: los simbolos de los que depende el mod cliente de MR
# deben seguir definidos Y exportados en lua/. Una mencion en un comentario no cuenta.
#   - "exportado" = linea de primer nivel `M.<simbolo> = <identificador>` (o `function M.<simbolo>(`),
#     con RHS distinto de nil y, si es un identificador simple, definido en el mismo archivo.
#   - globales = `function TriggerServerEvent(` / `function AddEventHandler(` de primer nivel.
#   - extension beammp/multiplayer = el archivo existe y modScript.lua la sigue cargando.
# Exit: 0 todo presente | 1 falta algun simbolo/archivo
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

EXT="lua/ge/extensions"
fails=0
checked=0

ok()  { printf 'ok     %s\n' "$1"; }
bad() { printf 'FALLO [check_mr_contract]: %s\n' "$1" >&2; fails=$((fails + 1)); }

if [ ! -d lua ]; then
  echo "FALLO [check_mr_contract]: no existe el directorio lua/ (no se puede dar un resultado fiable)" >&2
  exit 1
fi

# check_export <archivo> <modulo> <simbolo>
check_export() {
  local file="$1" module="$2" sym="$3" line rhs
  checked=$((checked + 1))
  if [ ! -f "$file" ]; then
    bad "$module.$sym: no existe $file"
    return
  fi
  line="$(grep -E "^(M\.${sym}[[:space:]]*=|function[[:space:]]+M\.${sym}[[:space:]]*\()" "$file" | head -n 1 || true)"
  if [ -z "$line" ]; then
    bad "$module.$sym: sin exportacion 'M.$sym = ...' en $file"
    return
  fi
  if [[ "$line" == function* ]]; then
    ok "$module.$sym (function M.$sym en $file)"
    return
  fi
  rhs="${line#*=}"
  rhs="${rhs//$'\r'/}"
  rhs="${rhs%%--*}"
  rhs="${rhs#"${rhs%%[![:space:]]*}"}"
  rhs="${rhs%"${rhs##*[![:space:]]}"}"
  if [ -z "$rhs" ] || [ "$rhs" = "nil" ]; then
    bad "$module.$sym: exportado como vacio/nil en $file"
    return
  fi
  if [[ "$rhs" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
    if ! grep -Eq "^[[:space:]]*(local[[:space:]]+function|function|local)[[:space:]]+${rhs}([^A-Za-z0-9_]|\$)" "$file"; then
      bad "$module.$sym: exporta '$rhs' pero '$rhs' no esta definido en $file"
      return
    fi
  fi
  ok "$module.$sym = $rhs ($file)"
}

# check_global <simbolo>
check_global() {
  local sym="$1"
  checked=$((checked + 1))
  if grep -rEq --include='*.lua' "^(function[[:space:]]+${sym}[[:space:]]*\(|${sym}[[:space:]]*=[[:space:]]*(function|[A-Za-z_]))" lua; then
    ok "global $sym definido en lua/"
  else
    bad "global $sym: no hay 'function $sym(' de primer nivel en lua/"
  fi
}

VEH="$EXT/MPVehicleGE.lua"
for sym in getVehicles isOwn getPlayers hideNicknames onPreRender getVehicleByGameID; do
  check_export "$VEH" MPVehicleGE "$sym"
done

# onServerVehicleResetted: en la base upstream es una funcion LOCAL de MPVehicleGE.lua
# (la invoca el manejador de red 'r'); upstream NO la exporta en M. Se exige por tanto que
# siga definida y siga siendo llamada, y se deja constancia de que no es un export.
checked=$((checked + 1))
if [ -f "$VEH" ] \
   && grep -Eq '^local function onServerVehicleResetted[[:space:]]*\(' "$VEH" \
   && grep -Eq '^[[:space:]]+onServerVehicleResetted[[:space:]]*\(' "$VEH"; then
  ok "MPVehicleGE.onServerVehicleResetted (funcion local definida y usada; upstream no la exporta en M)"
else
  bad "MPVehicleGE.onServerVehicleResetted: falta la funcion local o su llamada en $VEH"
fi

check_export "$EXT/MPGameNetwork.lua" MPGameNetwork launcherConnected
for sym in leaveServer disconnectLauncher isMPSession; do
  check_export "$EXT/MPCoreNetwork.lua" MPCoreNetwork "$sym"
done
check_export "$EXT/MPConfig.lua" MPConfig getNickname
check_export "$EXT/MPModManager.lua" MPModManager getServerMods
for sym in setPosition setPositionRotationVelocity; do
  check_export "$EXT/positionGE.lua" positionGE "$sym"
done

check_global TriggerServerEvent
check_global AddEventHandler

# Extension beammp/multiplayer: archivo que la define + modScript.lua la sigue cargando.
checked=$((checked + 1))
if [ ! -f "$EXT/beammp/multiplayer.lua" ]; then
  bad "extension beammp/multiplayer: no existe $EXT/beammp/multiplayer.lua"
elif ! grep -Eq '^return[[:space:]]+M' "$EXT/beammp/multiplayer.lua"; then
  bad "extension beammp/multiplayer: $EXT/beammp/multiplayer.lua no devuelve el modulo ('return M')"
elif [ ! -f scripts/BeamMP/modScript.lua ]; then
  bad "extension beammp/multiplayer: no existe scripts/BeamMP/modScript.lua"
elif ! grep -Eq '^load\("beammp/multiplayer"\)' scripts/BeamMP/modScript.lua; then
  bad "extension beammp/multiplayer: modScript.lua ya no hace load(\"beammp/multiplayer\")"
else
  ok "extension beammp/multiplayer (archivo presente y cargada por modScript.lua)"
fi

if [ "$fails" -ne 0 ]; then
  echo "check_mr_contract: $fails de $checked comprobaciones fallaron." >&2
  exit 1
fi
echo "check_mr_contract OK: $checked comprobaciones."
