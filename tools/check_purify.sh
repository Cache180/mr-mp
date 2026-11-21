#!/usr/bin/env bash
# Copyright (C) 2026 Muertazos Racing
# Licensed under AGPL-3.0 (or later), see <https://www.gnu.org/licenses/>.
# SPDX-License-Identifier: AGPL-3.0-or-later
#
# Guardian de carga segura de DOMPurify. Las apps de HUD BeamMP-Session y BeamMP-Chat
# cargan purify.min.js con un import() en segundo plano, asi que el objeto global
# DOMPurify puede no existir todavia cuando se intenta usar. Usarlo antes de tiempo
# lanza una excepcion (p. ej. no se muestra el nombre del servidor) y, peor, invita a
# saltarse el saneado.
#
# Regla DIRIGIDA y documentada: en esos dos archivos, toda linea que contenga un uso de
# DOMPurify (el token "DOMPurify" seguido de ".") DEBE contener tambien el testigo de
# disponibilidad "purifyReady" en la MISMA linea (la espera de la carga). Asi el uso solo
# ocurre cuando el flag confirma que el import() ya resolvio; mientras no, el codigo debe
# caer a texto plano. Cualquier uso de DOMPurify sin "purifyReady" en su linea falla.
#
# Solo se inspeccionan esos dos archivos (busqueda dirigida, no un barrido de todo el UI).
# Exit: 0 limpio | 1 uso sin proteger o archivo ausente
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

files=(
  "ui/modules/apps/BeamMP-Session/app.js"
  "ui/modules/apps/BeamMP-Chat/app.js"
)

status=0
for f in "${files[@]}"; do
  if [ ! -f "$f" ]; then
    echo "FALLO [check_purify]: falta el archivo a inspeccionar: $f" >&2
    status=1
    continue
  fi
  # Lineas con un uso de DOMPurify que NO esten detras de la espera (sin "purifyReady").
  unguarded="$(grep -nE 'DOMPurify\.' "$f" | grep -v 'purifyReady' || true)"
  if [ -n "$unguarded" ]; then
    echo "FALLO [check_purify]: uso de DOMPurify sin espera de carga (falta 'purifyReady') en $f:" >&2
    echo "$unguarded" >&2
    status=1
  fi
done

if [ "$status" -eq 0 ]; then
  echo "check_purify OK: todo uso de DOMPurify esta detras de purifyReady en las ${#files[@]} apps."
fi
exit "$status"
