import std/[
  sequtils,
  strutils,
]

import ../../lib/leetcode/lcClient
import ../../projects/projects
import ../../nlccrcs
import ../../consts



proc getOutput(jso: JsonNode): string {.inline.} =
  jso.getElems.mapIt(it.getStr).join("\n")

proc runDiff(fa, fb: string): bool =
  if not fileExists(fa) or not fileExists(fb): return
  let ca = readFile(fa).strip(leading = false)
  let cb = readFile(fb).strip(leading = false)
  if ca == cb:
    echo "SUCCESS"
    return true
  else:
    let cmd = nlccrc.getDiffCmd()
      .replace(TMPL_VAR_DIFF_A, fa)
      .replace(TMPL_VAR_DIFF_B, fb)
    discard execShellCmd(cmd)

proc testCmd*(proj: BaseProject): bool =
  let client = newLcClient()
  client.setToken(nlccrc.getLeetCodeSession)

  let res = proj.test(client)

  let output = getOutput(res["code_output"])
  if output.len > 0:
    echo "Code output:"
    echo output

  # Runtime Error
  if not res["run_success"].getBool:
    echo res["full_runtime_error"].getStr
    return

  # compare output
  writeFile(proj.testMyOutputFn, getOutput(res["code_answer"]))
  if not fileExists(proj.testOutputFn):
    proj.openInEditor(proj.testMyOutputFn)
  else:
    if not runDiff(proj.testOutputFn, proj.testMyOutputFn): return

  echo "Runtime: ", res["status_runtime"].getStr
  echo "Memory: ", res["status_memory"].getStr

  true
