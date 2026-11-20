// Copyright (C) 2026 Muertazos Racing
// Licensed under AGPL-3.0 (or later), see <https://www.gnu.org/licenses/>.
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Utilidades comunes de los guardianes de UI (check_brand, check_vue, check_json).
// Solo se usan en CI/desarrollo; nada de esto se empaqueta en el mod (ver el paso "Build MRMP.zip").
"use strict"

const cp = require("child_process")
const fs = require("fs")
const path = require("path")

const ROOT = path.resolve(__dirname, "..")

function fail(message) {
  process.stderr.write(`FALLO: ${message}\n`)
  process.exit(1)
}

// Carga @vue/compiler-sfc desde MR_SFC_DIR (el CI lo instala fuera del repo) o desde cwd. Si no esta, FALLA:
// un guardian que no puede analizar no puede aprobar.
function loadCompiler() {
  const paths = [process.env.MR_SFC_DIR, process.cwd(), __dirname].filter(Boolean)
  try {
    const resolved = require.resolve("@vue/compiler-sfc", { paths })
    return require(resolved)
  } catch (error) {
    return fail("no se encuentra @vue/compiler-sfc (instalalo y apunta MR_SFC_DIR a su carpeta): " + error.message)
  }
}

// Archivos versionados (HEAD + indice), rutas relativas con "/".
function trackedFiles() {
  const out = cp.execFileSync("git", ["ls-files", "-z"], { cwd: ROOT, maxBuffer: 1 << 28 })
  return out.toString("utf8").split("\0").filter(Boolean)
}

// Archivos anadidos/copiados/modificados/renombrados (NO borrados) entre base y HEAD.
// MR_WORKTREE=1 (solo uso local) compara la base con el arbol de trabajo en vez de con HEAD.
function changedFiles(base) {
  if (!/^[0-9a-f]{40}$/.test(base)) fail(`la base debe ser un sha completo de 40 hex, recibido: '${base}'`)
  try {
    cp.execFileSync("git", ["cat-file", "-e", `${base}^{commit}`], { cwd: ROOT, stdio: "ignore" })
  } catch {
    fail(`el commit base ${base} no esta en este checkout (checkout superficial? usa fetch-depth: 0)`)
  }
  const target = process.env.MR_WORKTREE === "1" ? [] : ["HEAD"]
  const out = cp.execFileSync(
    "git",
    ["diff", "--name-only", "--no-renames", "--diff-filter=ACMRT", "-z", base, ...target],
    { cwd: ROOT, maxBuffer: 1 << 28 },
  )
  return out.toString("utf8").split("\0").filter(Boolean)
}

// Contenido de un archivo en la base (null si no existia).
function baseContent(base, file) {
  try {
    return cp.execFileSync("git", ["show", `${base}:${file}`], { cwd: ROOT, maxBuffer: 1 << 28, stdio: ["ignore", "pipe", "ignore"] }).toString("utf8")
  } catch {
    return null
  }
}

function readText(file) {
  return fs.readFileSync(path.join(ROOT, file), "utf8").replace(/^﻿/, "")
}

// Argumento de base: primer argumento o contenido de tools/base-sha.txt.
function resolveBase(argv) {
  if (argv[0]) return argv[0].trim()
  return fs.readFileSync(path.join(ROOT, "tools", "base-sha.txt"), "utf8").trim()
}

module.exports = { ROOT, fail, loadCompiler, trackedFiles, changedFiles, baseContent, readText, resolveBase }
