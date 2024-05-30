import std/[
  strutils,
]

import ../../lib/leetcode/lcClient
import ../../projects/projects
import ../../nlccrcs
import ../../consts
import utils



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

  showCodeOutput(res)

  # Runtime Error
  if showRuntimeError(res): return

  discard showStatus(res)

  # compare output
  writeFile(proj.testMyOutputFn, getOutput(res["code_answer"]))
  if not fileExists(proj.testOutputFn):
    proj.openInEditor(proj.testMyOutputFn)
  else:
    if not runDiff(proj.testOutputFn, proj.testMyOutputFn): return

  showRuntimeMemory(res)

  true
