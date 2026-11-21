#!/usr/bin/env bash
# Copyright (C) 2026 Muertazos Racing
# Licensed under AGPL-3.0 (or later), see <https://www.gnu.org/licenses/>.
# SPDX-License-Identifier: AGPL-3.0-or-later
#
# Guardian de carga segura de DOMPurify. Las apps de HUD BeamMP-Session y BeamMP-Chat
# cargan purify.min.js con un import() en segundo plano, asi que el objeto global
# DOMPurify puede no existir todavia cuando se intenta usar. Usarlo antes de tiempo
# lanza una excepcion (p. ej. no se muestra el nombre del servidor) e invita a saltarse
# el saneado; el codigo debe esperar a la carga y, mientras, caer a texto plano.
#
# Regla DIRIGIDA (heuristica, NO un analizador de JS). En esos dos archivos:
#   1. Se quita de cada linea su comentario de linea/final (todo desde el primer "//").
#   2. Si en lo que queda (el codigo) no aparece el token "DOMPurify", la linea pasa.
#   3. Si aparece, DEBE formar parte EXACTA de la subcadena  purifyReady ? DOMPurify.sanitize(
#      (con esos espacios). Se borra esa subcadena permitida; si aun queda algun "DOMPurify",
#      la linea falla.
#
# QUE CAZA (todas fallan):
#   - alias:                const P = DOMPurify
#   - acceso por corchetes: window["DOMPurify"]  /  DOMPurify[...]
#   - token suelto a fin de linea (y uso partido en dos lineas: "DOMPurify" al final y
#     ".sanitize(" en la siguiente)
#   - "purifyReady" solo en un comentario de linea (se quita antes de comprobar, no cuenta)
#   - espaciado distinto dentro del patron (p. ej. dos espacios) -> no casa -> falla
#
# QUE NO CAZA (es una heuristica, no se vende como mas): comentarios de bloque /* ... */,
#   reconstruir el nombre "DOMPurify" por concatenacion de cadenas, u ofuscaciones similares.
#   (Quitar el comentario en el primer "//" podria recortar una URL http://..., pero solo
#   importan las lineas con "DOMPurify" y ninguna de ellas lleva URLs, asi que no da falsos
#   positivos aqui.)
#
# Solo se inspeccionan esos dos archivos (busqueda dirigida, no un barrido de todo el UI).
# Exit: 0 limpio | 1 uso fuera del patron permitido o archivo ausente (falla cerrado)
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
  violations="$(awk '
    {
      code = $0
      sub(/\/\/.*/, "", code)                                 # quita comentario de linea/final
      if (code !~ /DOMPurify/) next                           # sin uso en codigo: nada que comprobar
      gsub(/purifyReady \? DOMPurify\.sanitize\(/, "", code)  # borra el unico uso permitido
      if (code ~ /DOMPurify/) printf("%d:%s\n", NR, $0)       # queda algun DOMPurify -> fuera del patron
    }
  ' "$f")"
  if [ -n "$violations" ]; then
    echo "FALLO [check_purify]: uso de DOMPurify fuera de 'purifyReady ? DOMPurify.sanitize(' en $f:" >&2
    echo "$violations" >&2
    status=1
  fi
done

if [ "$status" -eq 0 ]; then
  echo "check_purify OK: todo uso de DOMPurify esta en el patron permitido en las ${#files[@]} apps."
fi
exit "$status"
