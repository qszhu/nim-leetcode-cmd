import std/[
  sequtils,
  strformat,
  strutils,
]

import ../baseProject
import ../utils
import ../../consts



const TMPL_ROOT = "tmpl" / "python3"
const TMPL_FN = TMPL_ROOT / "solution.tmpl"

const TMPL_VAR_CODE = "${code}"
const TMPL_VAR_PROBLEM_DESC = "${problemDesc}"
const TMPL_VAR_PROBLEM_DESC_EN = "${problemDescEn}"

const TMPL_DRIVER_FN = TMPL_ROOT / "driver.tmpl"

const TMPL_VAR_DRIVER_LOOP = "${driverLoop}"

proc genCode(code, problemDesc, problemDescEn: string): string =
  let tmpl = readFile(TMPL_FN)
  result = tmpl
    .replace(TMPL_VAR_CODE, code)
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

method build*(self: Python3Project): bool =
  copyFile(self.curSolutionFn, self.targetFn)
  true

proc genParam(i: int, typ: string): string {.inline.} =
  &"""
        line = next(lines, None)
        if line == None:
          break
        param_{i} = des._deserialize(line, '{typ}')
"""

proc genCall(name: string, numParams: int): string {.inline.} =
  let params = (1 .. numParams).mapIt(&"param_{it}").join(", ")
  &"""
        ret = Solution().{name}({params})
"""

proc genReturn(typ: string): string {.inline.} =
  &"""
        try:
            out = ser._serialize(ret, '{typ}')
        except:
            raise TypeError(str(ret) + " is not valid value for the expected return type {typ}");
"""

proc genDriverLoop(metaData: JsonNode): string =
  let params = metaData["params"].getElems
  var getParams = newSeq[string]()
  for i, param in params:
    getParams.add genParam(i + 1, param["type"].getStr)
  let getParamsCode = getParams.join("\n")
  let callCode = genCall(metaData["name"].getStr, metaData["params"].len)
  let returnCode = genReturn(metaData["return"]["type"].getStr)
  &"""
    while True:
{getParamsCode}
{callCode}
{returnCode}
        out = str.encode(out + '\n')
        f.write(out)
        sys.stdout.write(SEPARATOR)
"""

method localTest*(self: Python3Project) =
  if not checkCmd("python3.11"):
    echo "Missing python3.11"
    return

  let code = readFile(self.targetFn)
  let driverLoop = genDriverLoop(self.info.metaData)
  let tmpl = readFile(TMPL_DRIVER_FN)
  let driverCode = tmpl
    .replace(TMPL_VAR_CODE, code)
    .replace(TMPL_VAR_DRIVER_LOOP, driverLoop)
  let wd = "precompiled" / "python3"
  writeFile(wd / "driver.py", driverCode)

  let cmd = &"""cd {wd} && python3.11 driver.py -recursion_limit 550000 < {self.testInputFn.absolutePath}"""
  echo cmd
  if execShellCmd(cmd) != 0: return
  copyFile(wd / "user.out", self.testMyOutputFn)



when isMainModule:
  let metaData = """{"name":"minimumChairs","params":[{"name":"s","type":"string"}],"return":{"type":"integer"}}""".parseJson
  echo genDriverLoop(metaData)
