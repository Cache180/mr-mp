// Copyright (C) 2026 Muertazos Racing
// Licensed under AGPL-3.0 (or later), see <https://www.gnu.org/licenses/>.
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Guardian de marca: ninguna cadena VISIBLE del mod puede decir BeamMP ni apuntar a servicios de BeamMP
// (beammp.com, patreon, forum.beammp...), salvo el aviso de licencia/origen de la vista de terminos.
// Se llama desde tools/check_brand.sh. Nombres internos (rutas, eventos, clases CSS, claves de locales,
// ids) NO son visibles y no se comprueban: solo se miran los textos que ve el jugador.
//
// Que se considera "visible":
//   - locales/**/*.json: TODOS los valores (las claves no).
//   - ui/modules/apps/*/app.json: "name" y "description".
//   - settings/ui_apps/layouts/**/*.json: "title".
//   - Plantillas .vue y .html de ui/ui-vue/mods y ui/modules/apps: nodos de texto, interpolaciones,
//     atributos de texto visible (alt, title, placeholder, aria-label, label, message...), y cualquier
//     enlace/URL a servicios de BeamMP en cualquier atributo o expresion.
//   - Scripts (.vue, .js) de esas mismas rutas: literales de cadena que son frases (con espacios) o que
//     son exactamente "BeamMP", y cualquier URL a servicios de BeamMP.
// Exit: 0 limpio | 1 violacion, categoria vacia (no se puede pasar en vacio) o herramienta ausente.
"use strict"

const { fail, loadCompiler, trackedFiles, readText } = require("./mr_sfc.js")

// Texto corrido (valores de locales, texto de plantilla): cualquier aparicion cuenta.
const PROSE = /beam\s?-?mp|patreon/i
// Enlaces a servicios de BeamMP (en cualquier cadena: URLs de expresiones, atributos, scripts).
const SERVICE_URL = /beammp\.com|patreon\.com|github\.com\/beammp|discord\.gg\/beammp|discord(?:app)?\.com\/invite\/beammp/i
// Literales de script: la marca solo cuenta como palabra suelta, no dentro de identificadores, rutas, ids
// o claves (onBeamMPLoggedIn, /ui/assets/BeamMP, menu.beammp, ui.beammp.x, BeamMP.routes).
const STANDALONE = "(?<![A-Za-z0-9_\\/.-])BRAND(?![A-Za-z0-9_\\/-]|\\.[A-Za-z0-9_])"
const STANDALONE_CS = new RegExp(STANDALONE.replace("BRAND", "(?:BeamMP|Beam MP|BEAMMP)"))
const STANDALONE_CI = new RegExp(STANDALONE.replace("BRAND", "beam\\s?-?mp"), "i")
// Atributos estaticos cuyo valor es texto que ve el jugador. Incluye "value" (texto de inputs/opciones)
// y cualquier "data-*" (datos que suelen acabar en pantalla); estos ultimos se detectan por prefijo.
const VISIBLE_ATTRS = new Set([
  "alt", "title", "placeholder", "aria-label", "label", "text", "message", "description",
  "tooltip", "confirm-text", "cancel-text", "subtitle", "header", "value",
])
const isVisibleAttr = name => VISIBLE_ATTRS.has(name) || name.startsWith("data-")
// Atributos enlazados que son ganchos internos (clases, ids...), no texto.
const HOOK_ARGS = new Set(["class", "style", "id", "key", "ref", "name", "for"])

const NOTICE_FILE = "ui/ui-vue/mods/BeamMP/views/BeamMPTOSView.vue"
const NOTICE_TEXT = "MR Multiplayer esta basado en BeamMP (AGPL-3.0). Codigo fuente: github.com/Cache180/mr-mp"
const NOTICE_BEGIN = /<!--\s*license-notice:begin\s*-->/g
const NOTICE_END = /<!--\s*license-notice:end\s*-->/g
const NOTICE_BLOCK = /<!--\s*license-notice:begin\s*-->([\s\S]*?)<!--\s*license-notice:end\s*-->/g

// Sin analizar expresiones JS: las plantillas Angular (app.html) llevan {{:: x | translate}}, que no es JS.
const PARSE_OPTIONS = filename => ({ filename, parseExpressions: false, templateParseOptions: { prefixIdentifiers: false } })

const violations = []
const filesWithHits = new Set()
const counts = { locales: 0, appJson: 0, layoutJson: 0, templates: 0, scripts: 0 }

function report(file, line, rule, text) {
  filesWithHits.add(file)
  const snippet = String(text).replace(/\s+/g, " ").trim().slice(0, 120)
  violations.push(`FALLO [check_brand]: ${file}${line ? ":" + line : ""}: ${rule}: "${snippet}"`)
}

const proseHit = text => PROSE.test(text) || SERVICE_URL.test(text)
const literalHit = text => SERVICE_URL.test(text) || STANDALONE_CS.test(text) || (/\s/.test(text) && STANDALONE_CI.test(text))

// ---------- JSON ----------
function walkJsonValues(value, visit, keyPath = "") {
  if (typeof value === "string") visit(value, keyPath)
  else if (Array.isArray(value)) value.forEach((item, i) => walkJsonValues(item, visit, `${keyPath}[${i}]`))
  else if (value && typeof value === "object") {
    for (const [k, v] of Object.entries(value)) walkJsonValues(v, visit, keyPath ? `${keyPath}.${k}` : k)
  }
}

function parseJson(file) {
  try {
    return JSON.parse(readText(file))
  } catch (error) {
    report(file, 0, "JSON no valido", error.message)
    return null
  }
}

function checkLocale(file) {
  counts.locales++
  const json = parseJson(file)
  if (!json) return
  walkJsonValues(json, (value, key) => {
    if (proseHit(value)) report(file, 0, `valor de locale ${key}`, value)
  })
}

function checkAppJson(file) {
  counts.appJson++
  const json = parseJson(file)
  if (!json) return
  for (const field of ["name", "description"]) {
    if (typeof json[field] === "string" && proseHit(json[field])) report(file, 0, `app.json "${field}"`, json[field])
  }
}

function checkLayoutJson(file) {
  counts.layoutJson++
  const json = parseJson(file)
  if (!json) return
  if (typeof json.title === "string" && proseHit(json.title)) report(file, 0, 'uilayout "title"', json.title)
}

// ---------- Scripts (babel) ----------
function collectScriptLiterals(compiler, code, lineOffset, file) {
  let ast
  try {
    ast = compiler.babelParse(code, { sourceType: "unambiguous", plugins: ["typescript"] })
  } catch (error) {
    report(file, 0, "no se puede analizar el script", error.message)
    return
  }
  const stack = [ast]
  while (stack.length) {
    const node = stack.pop()
    if (!node || typeof node.type !== "string") continue
    if (node.type === "StringLiteral" && literalHit(node.value)) {
      report(file, node.loc.start.line + lineOffset, "literal de script visible", node.value)
    } else if (node.type === "TemplateLiteral") {
      const joined = node.quasis.map(q => q.value.cooked ?? q.value.raw).join("{}")
      if (literalHit(joined)) report(file, node.loc.start.line + lineOffset, "literal de script visible", joined)
    }
    for (const [key, child] of Object.entries(node)) {
      if (key === "loc" || key === "extra" || key === "leadingComments" || key === "trailingComments" || key === "innerComments") continue
      if (Array.isArray(child)) child.forEach(c => c && typeof c.type === "string" && stack.push(c))
      else if (child && typeof child.type === "string") stack.push(child)
    }
  }
}

// ---------- Plantillas ----------
function expressionLiterals(expression) {
  const found = []
  const re = /(['"`])((?:\\.|(?!\1)[^\\])*)\1/g
  let match
  while ((match = re.exec(expression)) !== null) found.push(match[2])
  return found
}

function checkExpression(file, line, expression) {
  for (const text of expressionLiterals(expression)) {
    if (literalHit(text)) report(file, line, "literal de expresion visible", text)
  }
}

function walkTemplate(file, node) {
  const line = node.loc?.start?.line || 0
  switch (node.type) {
    case 2: // TEXT
      if (proseHit(node.content)) report(file, line, "texto de plantilla", node.content)
      break
    case 5: // INTERPOLATION
      checkExpression(file, line, node.content?.content || "")
      break
    case 1: // ELEMENT
      for (const prop of node.props || []) {
        const propLine = prop.loc?.start?.line || line
        if (prop.type === 6) {
          const value = prop.value?.content || ""
          if (isVisibleAttr(prop.name.toLowerCase())) {
            // Lo que va entre {{ }} es una expresion: se mira con la regla de literales (las claves de locales
            // como ui.beammp.x no son texto visible); el resto del valor es texto corrido.
            const interpolations = [...value.matchAll(/\{\{([\s\S]*?)\}\}/g)]
            for (const m of interpolations) checkExpression(file, propLine, m[1])
            const prose = value.replace(/\{\{[\s\S]*?\}\}/g, " ")
            if (proseHit(prose)) report(file, propLine, `atributo visible ${prop.name}`, value)
          } else if (!HOOK_ARGS.has(prop.name.toLowerCase()) && SERVICE_URL.test(value)) {
            report(file, propLine, `enlace a servicio de BeamMP en ${prop.name}`, value)
          }
        } else if (prop.type === 7 && prop.exp?.content) {
          const arg = prop.arg?.content
          if (prop.name === "bind" && HOOK_ARGS.has(String(arg))) continue
          checkExpression(file, propLine, prop.exp.content)
        }
      }
      break
    default:
      break
  }
  for (const child of node.children || []) walkTemplate(file, child)
}

// Quita el bloque del aviso de licencia (solo permitido en NOTICE_FILE, una vez, y con el texto exacto).
function stripNotice(file, source) {
  const begins = (source.match(NOTICE_BEGIN) || []).length
  const ends = (source.match(NOTICE_END) || []).length
  const blocks = [...source.matchAll(NOTICE_BLOCK)]
  if (begins === 0 && ends === 0) return source
  if (file !== NOTICE_FILE) {
    report(file, 0, "exencion de aviso de licencia fuera de su vista", `solo se permite en ${NOTICE_FILE}`)
    return source
  }
  if (begins !== 1 || ends !== 1 || blocks.length !== 1) {
    report(file, 0, "marcas del aviso de licencia mal formadas", `begin=${begins} end=${ends} bloques=${blocks.length}`)
    return source
  }
  const visible = blocks[0][1].replace(/<[^>]*>/g, " ").replace(/\s+/g, " ").trim()
  if (!visible.includes(NOTICE_TEXT)) {
    report(file, 0, "el aviso de licencia no contiene el texto exacto", NOTICE_TEXT)
  }
  return source.replace(NOTICE_BLOCK, "")
}

function checkTemplateSource(compiler, file, wrapped, label) {
  const { descriptor, errors } = compiler.parse(wrapped, PARSE_OPTIONS(file))
  if (errors.length) {
    report(file, 0, `no se puede analizar la plantilla (${label})`, errors[0].message || String(errors[0]))
    return
  }
  if (!descriptor.template?.ast) {
    report(file, 0, "sin plantilla analizable", label)
    return
  }
  counts.templates++
  walkTemplate(file, descriptor.template.ast)
}

// Valores de la propiedad CSS content: (p. ej. content: "BeamMP") son texto que ve el jugador.
function checkStyleContent(file, block) {
  const base = block.loc.start.line - 1
  const re = /content\s*:\s*(['"])((?:\\.|(?!\1)[^\\])*)\1/g
  let match
  while ((match = re.exec(block.content)) !== null) {
    if (proseHit(match[2])) {
      const line = base + block.content.slice(0, match.index).split("\n").length
      report(file, line, "CSS content visible", match[2])
    }
  }
}

function checkVue(compiler, file) {
  const source = stripNotice(file, readText(file))
  const { descriptor, errors } = compiler.parse(source, PARSE_OPTIONS(file))
  if (errors.length) {
    report(file, 0, "SFC no analizable", errors[0].message || String(errors[0]))
    return
  }
  if (descriptor.template?.ast) {
    counts.templates++
    walkTemplate(file, descriptor.template.ast)
  }
  for (const block of [descriptor.script, descriptor.scriptSetup]) {
    if (!block) continue
    counts.scripts++
    collectScriptLiterals(compiler, block.content, block.loc.start.line - 1, file)
  }
  for (const style of descriptor.styles) checkStyleContent(file, style)
}

function checkHtml(compiler, file) {
  checkTemplateSource(compiler, file, `<template>${readText(file)}</template>`, "html")
}

function checkJs(compiler, file) {
  counts.scripts++
  collectScriptLiterals(compiler, readText(file), 0, file)
}

// ---------- Imagenes con marca (R18: no se redistribuye el logo de BeamMP ni marcas de terceros) ----------
const BRAND_IMAGE_NAME = /(?:beammp|patreon|clyde|github-mark)[^/]*\.(?:png|svg|jpe?g|gif|webp|ico)$/i
const BAKED_BRAND_IMAGE = /^ui\/modules\/apps\/[^/]+\/app\.png$/

function checkImage(file) {
  if (BRAND_IMAGE_NAME.test(file)) report(file, 0, "imagen con marca (logo de BeamMP o de terceros)", file)
  else if (BAKED_BRAND_IMAGE.test(file)) report(file, 0, "vista previa de app con el nombre BeamMP incrustado", file)
}

// ---------- Textos visibles en Lua (R19): comprobacion DIRIGIDA, no un barrido de Lua ----------
// El Lua esta lleno de identificadores internos (BeamMP en nombres de eventos, rutas, ids), asi que solo se
// miran las lineas que fijan texto de pantalla. Cada localizador DEBE encontrar al menos una linea (fail closed).
const LUA_DISPLAY_SITES = [
  { file: "scripts/BeamMP/modScript.lua", what: "titulo/descripcion de la categoria de controles", find: /core_input_categories\.beammp\s*=/ },
  { file: "lua/ge/extensions/MPModManager.lua", what: "aviso de mod incompatible", find: /"toastrMsg".*incompatible mod/ },
  { file: "lua/ge/extensions/UI.lua", what: "titulo mostrado de la ventana de chat (windowTitle)", find: /^\s*(?:local\s+)?windowTitle\s*=/ },
]
// Excepciones documentadas: no se comprueban. MPVehicleGE.lua: aviso de funcion obsoleta para desarrolladores
// (archivo central de sincronizacion; R19 prohibe tocarlo). El id de imgui "BeamMP Chat" (imgui.Begin /
// registerWindow en UI.lua) es un identificador (posicion guardada de la ventana) y tampoco se comprueba.
const LUA_EXEMPT = ["lua/ge/extensions/MPVehicleGE.lua"]

function checkLuaDisplay(file, site) {
  let hits = 0
  readText(file).split("\n").forEach((line, i) => {
    if (!site.find.test(line)) return
    hits++
    const code = line.replace(/\s--[^"']*$/, "")
    for (const text of expressionLiterals(code)) {
      if (PROSE.test(text)) report(file, i + 1, `texto visible de Lua (${site.what})`, text)
    }
  })
  if (hits === 0) report(file, 0, "localizador de texto visible de Lua sin coincidencias (guardian en vacio)", site.what)
}

// ---------- Recorrido ----------
const compiler = loadCompiler()
const files = trackedFiles()
const inScope = f => f.startsWith("ui/ui-vue/mods/") || f.startsWith("ui/modules/apps/")

for (const file of files) {
  if (/^locales\/.*\.json$/.test(file)) checkLocale(file)
  else if (/^ui\/modules\/apps\/[^/]+\/app\.json$/.test(file)) checkAppJson(file)
  else if (/^settings\/ui_apps\/layouts\/.*\.json$/.test(file)) checkLayoutJson(file)
  else if (inScope(file) && file.endsWith(".vue")) checkVue(compiler, file)
  else if (/^ui\/modules\/apps\/.*\.html$/.test(file)) checkHtml(compiler, file)
  else if (inScope(file) && file.endsWith(".js")) checkJs(compiler, file)
  else checkImage(file)
}

for (const site of LUA_DISPLAY_SITES) checkLuaDisplay(site.file, site)

// Fail closed: si una categoria esta vacia el guardian no ha mirado nada y no puede aprobar.
for (const [name, count] of Object.entries(counts)) {
  if (count === 0) violations.push(`FALLO [check_brand]: categoria '${name}' sin archivos analizados (guardian en vacio)`)
}
// El aviso de licencia debe seguir presente en su vista.
if (!readText(NOTICE_FILE).includes("license-notice:begin")) {
  violations.push(`FALLO [check_brand]: falta el bloque del aviso de licencia en ${NOTICE_FILE}`)
}

if (violations.length) {
  process.stderr.write(violations.join("\n") + "\n")
  process.stderr.write(`check_brand: ${violations.length} violaciones en ${filesWithHits.size} archivos.\n`)
  process.exit(1)
}
process.stdout.write(
  `check_brand OK: locales=${counts.locales} app.json=${counts.appJson} uilayout=${counts.layoutJson} `
  + `plantillas=${counts.templates} scripts=${counts.scripts}.\n`,
)
