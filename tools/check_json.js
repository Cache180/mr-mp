// Copyright (C) 2026 Muertazos Racing
// Licensed under AGPL-3.0 (or later), see <https://www.gnu.org/licenses/>.
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Guardian de JSON: cada .json cambiado respecto a la base upstream debe ser JSON valido (JSON.parse).
// Excepcion explicita: algunos archivos de BeamNG ya eran "JSON con comentarios" en upstream
// (p. ej. settings/mp_defaults.json empieza con //). Si la version de la BASE tampoco era JSON estricto, el
// archivo se acepta si es valido tras quitar comentarios y comas finales, y se avisa (no se oculta). Un
// archivo nuevo, o uno que en la base era JSON estricto, debe ser JSON estricto.
// Se llama desde tools/check_json.sh. Exit: 0 limpio | 1 JSON invalido o error de uso.
"use strict"

const { fail, changedFiles, baseContent, readText, resolveBase } = require("./mr_sfc.js")

const base = resolveBase(process.argv.slice(2))
const targets = changedFiles(base).filter(f => f.endsWith(".json"))

// Quita comentarios // y /* */ y comas finales, respetando las cadenas.
function relax(text) {
  let out = ""
  let i = 0
  while (i < text.length) {
    const ch = text[i]
    if (ch === '"') {
      let j = i + 1
      while (j < text.length && text[j] !== '"') j += text[j] === "\\" ? 2 : 1
      out += text.slice(i, j + 1)
      i = j + 1
    } else if (ch === "/" && text[i + 1] === "/") {
      while (i < text.length && text[i] !== "\n") i++
    } else if (ch === "/" && text[i + 1] === "*") {
      const end = text.indexOf("*/", i + 2)
      i = end < 0 ? text.length : end + 2
    } else {
      out += ch
      i++
    }
  }
  return out.replace(/,(\s*[}\]])/g, "$1")
}

function isStrictJson(text) {
  try {
    JSON.parse(text.replace(/^﻿/, ""))
    return true
  } catch {
    return false
  }
}

let checked = 0
let failures = 0
for (const file of targets) {
  checked++
  const text = readText(file)
  try {
    JSON.parse(text)
    continue
  } catch (error) {
    const baseText = baseContent(base, file)
    if (baseText !== null && !isStrictJson(baseText)) {
      try {
        JSON.parse(relax(text))
        process.stdout.write(`AVISO [check_json]: ${file}: no es JSON estricto, pero tampoco lo era en la base upstream; valido tras quitar comentarios/comas finales\n`)
        continue
      } catch (relaxedError) {
        failures++
        process.stderr.write(`FALLO [check_json]: ${file}: ${relaxedError.message}\n`)
        continue
      }
    }
    failures++
    process.stderr.write(`FALLO [check_json]: ${file}: ${error.message}\n`)
  }
}

// Fail closed: todo .json cambiado debe haberse comprobado.
if (checked !== targets.length) fail(`check_json: ${targets.length} .json cambiados pero ${checked} comprobados (guardian en vacio)`)
if (failures > 0) {
  process.stderr.write(`check_json: ${failures} de ${checked} archivos .json no son JSON valido.\n`)
  process.exit(1)
}
process.stdout.write(`check_json OK: ${checked} .json cambiados respecto a ${base.slice(0, 8)} son JSON valido.\n`)
