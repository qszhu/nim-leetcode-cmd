import std/[
  os,
  strformat,
]

import ../baseProject
import ../utils
import gencodes
import ../../consts



type
  NimJsProject* = ref object of BaseProject

proc initNimJsProject*(info: ProjectInfo): NimJsProject =
  result.new
  result.init(info)
  result.code = genCode(info.metaData)

method submitLang*(self: NimJsProject): SubmitLanguage {.inline.} =
  SubmitLanguage.JAVASCRIPT

method srcFileExt*(self: NimJsProject): string {.inline.} =
  "nim"

method targetFn*(self: NimJsProject): string {.inline.} =
  self.buildDir / "solution.js"

const TARGET = "node20.10.0"

method build*(self: NimJsProject): bool =
  checkCmd("nim")

  block:
    let cmd = &"nim js -d:nodejs -d:danger -o:{self.targetFn} {self.curSolutionFn}"
    echo cmd
    if execShellCmd(cmd) != 0: return

  checkCmd("esbuild")

  block:
    let cmd = &"esbuild {self.targetFn} --minify=true --platform=node --target={TARGET} --outfile={self.targetFn} --allow-overwrite"
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