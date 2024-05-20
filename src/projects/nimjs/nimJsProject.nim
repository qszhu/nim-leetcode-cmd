import std/[
  os,
  strformat,
]

import ../baseProject
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

method srcFileExt*(self: NimJsProject): string =
  "nim"

method targetFn*(self: NimJsProject): string =
  self.buildDir / "solution.js"

proc checkCmd(cmd: string): bool {.inline.} =
  execShellCmd(&"which {cmd}") == 0

const TARGET = "node20.10.0"

method build*(self: NimJsProject): bool =
  if not checkCmd("nim"):
    echo "Missing nim"
    return

  block:
    let cmd = &"nim js -d:nodejs -d:danger -o:{self.targetFn} {self.curSolutionFn}"
    echo cmd
    if execShellCmd(cmd) != 0: return

  if not checkCmd("esbuild"):
    echo "Missing esbuild"
    return

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