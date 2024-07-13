import std/[
  json,
  sequtils,
  strformat,
  strutils,
  tables,
  terminal,
]

import ../../projects/projects
import ../../utils
import ../../consts
import ../consts



proc showCountDown*(seconds: float) =
  var x = seconds.int

  let secs = x mod 60
  x = x div 60

  let mins = x mod 60
  x = x div 60

  let hours = x mod 24
  let days = x div 24

  refreshEcho &"Starts in: {days} days, {hours} hours, {mins} minutes, {secs} seconds."

proc showRuntimeError*(jso: JsonNode): bool =
  if "full_runtime_error" in jso:
    echo jso["full_runtime_error"].getStr
    return true

proc showStatus*(jso: JsonNode): string =
  result = jso["status_msg"].getStr
  let color =
    case result
    of STATUS_ACCEPTED: fgGreen
    of STATUS_WRONG_ANSWER: fgRed
    else: fgYellow
  styledEcho(color, result)#, resetStyle)

proc showPassedCases*(jso: JsonNode) =
  echo "Passed cases: ", jso["total_correct"].getInt, "/", jso["total_testcases"].getInt

proc showRuntimeMemory*(jso: JsonNode) =
  echo "Runtime: ", jso["status_runtime"].getStr
  echo "Memory: ", jso["status_memory"].getStr

proc showRank*(rank: JsonNode) =
  echo "Solved: ", rank["my_solved"].getElems.len
  echo "Score: ", rank["my_rank"]["score"].getInt
  echo "Rank: ", rank["my_rank"]["rank_v2"].getInt

proc getOutput*(jso: JsonNode): string {.inline.} =
  jso.getElems.mapIt(it.getStr).join("\n")

proc showStdOutput*(jso: JsonNode) =
  let output = jso["std_output"].getStr
  if output.len > 0:
    echo "stdout:"
    echo output

type
  CodeSnippets* = Table[string, string]

proc initCodeSnippetsClassic*(jso: JsonNode): CodeSnippets =
  for r in jso:
    result[r["value"].getStr] = r["defaultCode"].getStr

proc initCodeSnippets*(jso: JsonNode): CodeSnippets =
  for r in jso:
    result[r["langSlug"].getStr] = r["code"].getStr

proc initProject*(info: ProjectInfo): BaseProject =
  case info.lang
  of Language.NIM_JS:
    initNimJsProject(info)
  of Language.NIM_WASM:
    initNimWasmProject(info)
  of Language.PYTHON3:
    initPython3Project(info)
