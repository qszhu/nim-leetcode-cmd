import std/[
  strformat,
  strutils,
]

import ../baseProject
import ../../consts



const TMPL_FN = "python3.tmpl"

const TMPL_VAR_SNIPPET = "${code}"
const TMPL_VAR_PROBLEM_DESC = "${problemDesc}"
const TMPL_VAR_PROBLEM_DESC_EN = "${problemDescEn}"

proc ensureDefaultTmpl() =
  if fileExists(TMPL_FN): return
  let content = &"""
'''
{TMPL_VAR_PROBLEM_DESC_EN}
'''

{TMPL_VAR_SNIPPET}
"""
  writeFile(TMPL_FN, content)

proc genCode(snippet, problemDesc, problemDescEn: string): string =
  ensureDefaultTmpl()
  let tmpl = readFile(TMPL_FN)
  result = tmpl
    .replace(TMPL_VAR_SNIPPET, snippet)
    .replace(TMPL_VAR_PROBLEM_DESC, problemDesc)
    .replace(TMPL_VAR_PROBLEM_DESC_EN, problemDescEn)



type
  Python3Project* = ref object of BaseProject

proc initPython3Project*(info: ProjectInfo): Python3Project =
  result.new
  result.init(info)
  result.code = genCode(
    info.codeSnippets[$SubmitLanguage.PYTHON3],
    info.problemDesc,
    info.problemDescEn,
  )

method submitLang*(self: Python3Project): SubmitLanguage {.inline.} =
  SubmitLanguage.PYTHON3

method srcFileExt*(self: Python3Project): string {.inline.} =
  "py"

method targetFn*(self: Python3Project): string {.inline.} =
  self.buildDir / "solution.py"

method build*(self: Python3Project): bool {.inline.} =
  copyFile(self.curSolutionFn, self.targetFn)
  true
