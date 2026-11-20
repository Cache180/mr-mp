// Copyright (C) 2026 Muertazos Racing
// Licensed under AGPL-3.0 (or later), see <https://www.gnu.org/licenses/>.
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Guardian de compilacion de la UI: cada .vue cambiado respecto a la base upstream se parsea y compila con
// @vue/compiler-sfc (SFC + <script> / <script setup> + <template>) y no puede dar errores. Los .js de la UI
// cambiados deben analizarse sin errores de sintaxis. Los bloques <style> (scss) no se compilan (haria falta
// sass), pero se comprueba que sus llaves estan equilibradas.
//
// Si una version de la base ya fallaba por motivos ajenos al cambio, no se oculta: se informa y se compara el
// CONJUNTO de errores contra la base (solo se aceptan errores que ya estaban en la base).
// Se llama desde tools/check_vue.sh. Exit: 0 limpio | 1 error de compilacion o herramienta ausente.
"use strict"

const { fail, loadCompiler, changedFiles, baseContent, readText, resolveBase } = require("./mr_sfc.js")

const base = resolveBase(process.argv.slice(2))
const compiler = loadCompiler()

const normalise = message => String(message).replace(/\s*\(\d+:\d+\)/g, "").replace(/\s+/g, " ").trim()

// Llaves equilibradas fuera de comentarios y cadenas (comprobacion barata de SCSS/CSS).
function braceBalance(css) {
  const code = css
    .replace(/\/\*[\s\S]*?\*\//g, "")
    .replace(/(^|[^:])\/\/[^\n]*/g, "$1")
    .replace(/"(?:\\.|[^"\\\n])*"|'(?:\\.|[^'\\\n])*'/g, '""')
  let depth = 0
  for (const ch of code) {
    if (ch === "{") depth++
    else if (ch === "}") depth--
    if (depth < 0) return "llave de cierre sin abrir"
  }
  return depth === 0 ? null : `${depth} llave(s) sin cerrar`
}

function vueErrors(source, filename) {
  const errors = []
  const { descriptor, errors: parseErrors } = compiler.parse(source, { filename })
  for (const e of parseErrors) errors.push(`SFC: ${e.message || e}`)
  if (parseErrors.length) return errors

  let bindings
  if (descriptor.script || descriptor.scriptSetup) {
    try {
      bindings = compiler.compileScript(descriptor, { id: "mrcheck", inlineTemplate: false }).bindings
    } catch (e) {
      errors.push(`script: ${e.message}`)
    }
  }
  if (descriptor.template) {
    const result = compiler.compileTemplate({
      source: descriptor.template.content,
      filename,
      id: "mrcheck",
      compilerOptions: { bindingMetadata: bindings },
    })
    for (const e of result.errors) errors.push(`template: ${e.message || e}`)
  } else if (!descriptor.script && !descriptor.scriptSetup) {
    errors.push("SFC sin <template> ni <script>")
  }
  for (const style of descriptor.styles) {
    const problem = braceBalance(style.content)
    if (problem) errors.push(`style: ${problem}`)
  }
  return errors
}

function jsErrors(source) {
  try {
    compiler.babelParse(source, { sourceType: "unambiguous", plugins: ["typescript"] })
    return []
  } catch (e) {
    return [`js: ${e.message}`]
  }
}

function errorsFor(file, source) {
  return file.endsWith(".vue") ? vueErrors(source, file) : jsErrors(source)
}

const changed = changedFiles(base)
const inScope = f => (f.startsWith("ui/ui-vue/mods/") || f.startsWith("ui/modules/apps/")) && (f.endsWith(".vue") || f.endsWith(".js"))
const targets = changed.filter(inScope)
const vueCount = changed.filter(f => f.endsWith(".vue")).length
let checked = 0
let vueChecked = 0
let failures = 0
let inherited = 0

for (const file of targets) {
  checked++
  if (file.endsWith(".vue")) vueChecked++
  const now = errorsFor(file, readText(file))
  if (now.length === 0) continue
  const baseSource = baseContent(base, file)
  const baseErrors = new Set((baseSource === null ? [] : errorsFor(file, baseSource)).map(normalise))
  const fresh = now.filter(e => !baseErrors.has(normalise(e)))
  const same = now.length - fresh.length
  if (same > 0) {
    inherited += same
    process.stdout.write(`AVISO [check_vue]: ${file}: ${same} error(es) ya presentes en la base upstream (no se ocultan, no cuentan como nuevos)\n`)
  }
  for (const e of fresh) {
    failures++
    process.stderr.write(`FALLO [check_vue]: ${file}: ${e}\n`)
  }
}

// Fail closed: si git dice que hay .vue cambiados, todos deben haberse comprobado.
if (vueChecked !== vueCount) {
  fail(`check_vue: ${vueCount} .vue cambiados pero ${vueChecked} comprobados (guardian en vacio)`)
}
if (failures > 0) {
  process.stderr.write(`check_vue: ${failures} error(es) nuevos en ${targets.length} archivos cambiados respecto a ${base}.\n`)
  process.exit(1)
}
process.stdout.write(
  `check_vue OK: ${vueChecked} .vue y ${checked - vueChecked} .js comprobados (cambiados respecto a ${base.slice(0, 8)}), `
  + `0 errores nuevos${inherited ? `, ${inherited} heredados de la base` : ""}.\n`,
)
