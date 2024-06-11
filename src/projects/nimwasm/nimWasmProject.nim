import std/[
  os,
  strformat,
  strutils,
]

import ../baseProject
import ../utils
import ../../consts



const TMPL_ROOT = "tmpl" / "nimwasm"
const TMPL_BUILD_FN = TMPL_ROOT / "build.tmpl"
const TMPL_POST_FN = TMPL_ROOT / "post.tmpl"
const TMPL_SOLUTION_FN = TMPL_ROOT / "solution.tmpl"

const TMPL_VAR_TARGET_FN = "${targetFn}"
const TMPL_VAR_SOLUTION_FN = "${solutionFn}"
const TMPL_VAR_POST_FN = "${postFn}"

proc ensureDefaultTmpl() =
  createDir(TMPL_ROOT)
  if not fileExists(TMPL_BUILD_FN):
    let content = &"""
nim c \
  -d:danger \
  --threads:off \
  --mm:arc \
  --cc:clang \
  --os:linux \
  --cpu:wasm32 \
  --clang.exe:emcc \
  --clang.linkerexe:emcc \
  --noMain:on \
  --passL:"-Os" \
  --passL:"-sSINGLE_FILE" \
  --passL:"-sWASM_ASYNC_COMPILATION=0" \
  --passL:"-sMODULARIZE" \
  --passL:"-sEXPORTED_FUNCTIONS=_solve,_malloc" \
  --passL:"-sEXPORTED_RUNTIME_METHODS=ccall,UTF8ToString" \
  --passL:"-sALLOW_MEMORY_GROWTH" \
  --passL:"--extern-post-js {TMPL_VAR_POST_FN}" \
  -o:{TMPL_VAR_TARGET_FN} \
  {TMPL_VAR_SOLUTION_FN}

esbuild {TMPL_VAR_TARGET_FN} \
  --target=node20.10.0 \
  --minify=true \
  --platform=node \
  --outfile={TMPL_VAR_TARGET_FN} \
  --allow-overwrite
"""
    writeFile(TMPL_BUILD_FN, content)

  if not fileExists(TMPL_POST_FN):
    let content = &"""
const fs = require('fs')
let lines = fs.readFileSync(0)

let inst = Module()
let buf = inst._malloc(lines.length)
inst.HEAPU8.set(lines, buf)

let resBuf = inst.ccall('solve', 'number', ['number'], [buf])
let output = inst.UTF8ToString(resBuf)
fs.writeFileSync("user.out", output)
process.exit(0)
"""
    writeFile(TMPL_POST_FN, content)

  if not fileExists(TMPL_SOLUTION_FN):
    let content = &"""
import ../../../../../lib/nimwasm/types

var
  s: string
  res: int

proc init() =
  discard

proc solve() =
  # TODO
  discard

proc output(): string =
  $res

proc main(lines: cstring): cstring {{.exportc: "solve".}} =
  init()
  let
    reader = newReader(lines)
    writer = newWriter()

  while reader.hasNext:
    s = reader.readString
    solve()
    writer.write output()

  writer.toCString

when isMainModule:
  echo $(main(stdin.readAll.cstring))
"""
    writeFile(TMPL_SOLUTION_FN, content)

type
  NimWasmProject* = ref object of BaseProject

proc initNimWasmProject*(info: ProjectInfo): NimWasmProject =
  result.new
  result.init(info)
  ensureDefaultTmpl()
  result.code = readFile(TMPL_SOLUTION_FN)

method submitLang*(self: NimWasmProject): SubmitLanguage {.inline.} =
  SubmitLanguage.JAVASCRIPT

method srcFileExt*(self: NimWasmProject): string =
  "nim"

method targetFn*(self: NimWasmProject): string =
  self.buildDir / "solution.js"

method build*(self: NimWasmProject): bool =
  if not checkCmd("nim"):
    echo "Missing nim"
    return

  if not checkCmd("emcc"):
    echo "Missing emcc"
    return

  if not checkCmd("esbuild"):
    echo "Missing esbuild"
    return

  block:
    let cmd = readFile(TMPL_BUILD_FN)
      .replace(TMPL_VAR_TARGET_FN, self.targetFn)
      .replace(TMPL_VAR_SOLUTION_FN, self.curSolutionFn)
      .replace(TMPL_VAR_POST_FN, TMPL_POST_FN)
    echo cmd
    if execShellCmd(cmd) != 0: return

  block:
    let src = readFile(self.curSolutionFn)
    let compiled = readFile(self.targetFn)
    let content = &"""
/*
{src}
*/

{compiled}
"""
    writeFile(self.targetFn, content)

  true
