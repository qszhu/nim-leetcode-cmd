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
  # In python, use spaces for tabs
  let problemDesc = problemDesc.replace("\t", "    ")
  let problemDescEn = problemDescEn.replace("\t", "    ")
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

proc genParam(i: int, name, typ: string): string {.inline.} =
  let i = i + 1
  if i == 1:
    &"""
        line = next(lines, None)
        if line == None:
          break
        param_{i} = des._deserialize(line, '{typ}')
"""
  else:
    &"""
        line = next(lines, None)
        if line == None:
            raise Exception("Testcase does not have enough input arguments. Expected argument '{name}'")
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
    getParams.add genParam(i, param["name"].getStr, param["type"].getStr)
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
  checkCmd("docker")

  let code = readFile(self.targetFn)
  let driverLoop = genDriverLoop(self.info.metaData)
  let tmpl = readFile(TMPL_DRIVER_FN)
  let driverCode = tmpl
    .replace(TMPL_VAR_CODE, code)
    .replace(TMPL_VAR_DRIVER_LOOP, driverLoop)
  let driverFn = self.buildDir / "driver.py"
  writeFile(driverFn, driverCode)
  writeFile(self.testMyOutputFn, "")

  let cmd = @[&"docker run --rm",
    &"-v {driverFn.absolutePath}:/usr/app/driver.py",
    &"-v {self.testInputFn.absolutePath}:/usr/app/input",
    &"-v {self.testMyOutputFn.absolutePath}:/usr/app/user.out",
    &"lcpython3.11 sh -c \"python driver.py -recursion_limit 550000 < input\"",
  ].join(" ")
  echo cmd
  if execShellCmd(cmd) != 0: return

const LAUNCH_NAME = "nlcc debug"
const LAUNCH_FN = ".vscode" / "launch.json"

proc readLaunchConfig(): JsonNode =
  if not fileExists(LAUNCH_FN):
    createDir(LAUNCH_FN.parentDir)
    writeFile(LAUNCH_FN, $(%*{
      "configurations": @[]
    }))
  readFile(LAUNCH_FN).parseJson

proc getDebugConfig(port: int, localRoot: string): JsonNode =
  %*{
    "name": LAUNCH_NAME,
    "type": "debugpy",
    "request": "attach",
    "connect": %*{
      "host": "localhost",
      "port": port,
    },
    "pathMappings": @[%*{
      "localRoot": localRoot,
      "remoteRoot": "/usr/app/",
    }]
  }

proc updateLaunchConfig(localDebugPort: int, localRoot: string) =
  var launchConfig = readLaunchConfig()
  let configs = launchConfig["configurations"].getElems
    .filterIt(it["name"].getStr != LAUNCH_NAME)
  launchConfig["configurations"] = %*(configs & getDebugConfig(localDebugPort, localRoot))
  writeFile(LAUNCH_FN, $launchConfig)

method debug*(self: Python3Project, port = 5678) =
  checkCmd("docker")

  updateLaunchConfig(port, self.buildDir.absolutePath)

  let code = readFile(self.targetFn)
  let driverLoop = genDriverLoop(self.info.metaData)
  let tmpl = readFile(TMPL_DRIVER_FN)
  let driverCode = tmpl
    .replace(TMPL_VAR_CODE, code)
    .replace(TMPL_VAR_DRIVER_LOOP, driverLoop)
  let driverFn = self.buildDir / "driver.py"
  writeFile(driverFn, driverCode)
  writeFile(self.testMyOutputFn, "")

  let cmd = @[&"docker run --rm",
    &"-v {driverFn.absolutePath}:/usr/app/driver.py",
    &"-v {self.testInputFn.absolutePath}:/usr/app/input",
    &"-v {self.testMyOutputFn.absolutePath}:/usr/app/user.out",
    &"-p {port}:5678",
    &"lcpython3.11 sh -c \"python -Xfrozen_modules=off -m debugpy --wait-for-client --listen 0.0.0.0:5678 driver.py -recursion_limit 550000 < input\"",
  ].join(" ")
  echo cmd
  if execShellCmd(cmd) != 0: return



when isMainModule:
  let metaData = """{"name":"minimumChairs","params":[{"name":"s","type":"string"}],"return":{"type":"integer"}}""".parseJson
  echo genDriverLoop(metaData)
