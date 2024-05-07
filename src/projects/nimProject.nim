import std/[
  json,
  os,
  strformat,
]

import baseProject
import nim/gencodes



type
  NimProject* = ref object of BaseProject

proc initNimProject*(info: ProjectInfo): NimProject =
  result.new
  result.init(info)
  result.code = genCode(info.metaData.parseJson)

method srcFileExt*(self: NimProject): string =
  "nim"

method targetFn*(self: NimProject): string =
  self.buildDir / "solution.js"

method build*(self: NimProject) =
  let cmd = &"nim js -d:nodejs -d:danger -o:{self.targetFn} {self.curSolutionFn}"
  #`esbuild ${project.solutionFn} --bundle --minify-syntax --platform=node --target=${TARGET} --outfile=${project.solutionFn} --allow-overwrite`
  discard execShellCmd(cmd)
