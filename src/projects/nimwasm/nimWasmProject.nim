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

type
  NimWasmProject* = ref object of BaseProject

proc initNimWasmProject*(info: ProjectInfo): NimWasmProject =
  result.new
  result.init(info)
  result.code = readFile(TMPL_SOLUTION_FN)

method submitLang*(self: NimWasmProject): SubmitLanguage {.inline.} =
  SubmitLanguage.JAVASCRIPT

method srcFileExt*(self: NimWasmProject): string {.inline.} =
  "nim"

method targetFn*(self: NimWasmProject): string {.inline.} =
  self.buildDir / "solution.js"

method build*(self: NimWasmProject): bool =
  checkCmd("nim")
  checkCmd("emcc")
  checkCmd("esbuild")

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

method localTest*(self: NimWasmProject) =
  checkCmd("docker")

  let driverFn = self.targetFn
  writeFile(self.testMyOutputFn, "")

  let cmd = @[&"docker run --rm",
    &"-v {driverFn.absolutePath}:/usr/app/driver.js",
    &"-v {self.testInputFn.absolutePath}:/usr/app/input",
    &"-v {self.testMyOutputFn.absolutePath}:/usr/app/user.out",
    &"lcnodejs20.10.0 sh -c \"node --harmony driver.js < input\"",
  ].join(" ")
  echo cmd
  if execShellCmd(cmd) != 0: return
