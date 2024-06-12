import std/[
  base64,
  sequtils,
  strformat,
  strutils,
]

import pkg/nimleetcode

import ../projects/baseProject



const WAIT_INTERVAL = 10 * 1000 # submission cooldown



type
  BasePuller = ref object of RootObj
    client: LcClient

method getFileList(self: BasePuller, dir: string): Future[seq[string]] {.base.} =
  raise newException(ValueError, "getFileList not implemented")

method getFileContent(self: BasePuller, fn: string): Future[string] {.base.} =
  raise newException(ValueError, "getFileContent not implemented")

method getDriverFn(self: BasePuller): string {.base, inline.} =
  raise newException(ValueError, "getDriverFn not implemented")



proc runPython3Code(client: LcClient, code: string): Future[JsonNode] {.async.} =
  let titleSlug = "two-sum"
  let questionId = "1"
  let lang = "python3"
  let code = &"""
class Solution:
    def twoSum(self, nums: List[int], target: int) -> List[int]:
{code}
"""
  let testInput = """
[2,7,11,5]
9
"""
  var res = await client.testSolution(titleSlug, questionId, lang, code, testInput)
  let interpretId = res["interpret_id"].getStr
  res = await client.checkResult(interpretId, false)
  return res["code_output"]

type
  Python3Puller = ref object of BasePuller

proc newPython3Puller(client: LcClient): Python3Puller =
  result.new
  result.client = client

method getFileList(self: Python3Puller, dir: string): Future[seq[string]] {.async.} =
  let code = &"""
        for fn in os.listdir('{dir}'):
            print(fn)
"""
  let outputs = await self.client.runPython3Code(code)
  return outputs.mapIt(it.getStr)

method getFileContent(self: Python3Puller, fn: string): Future[string] {.async.} =
  let code = &"""
        import base64
        with open({fn}, 'rb') as f:
            print(base64.b64encode(f.read()))
"""
  let outputs = await self.client.runPython3Code(code)
  let s = outputs[0].getStr
  let i = s.find("'")
  let j = s.rfind("'")
  return base64.decode(s[i + 1 ..< j])

method getDriverFn(self: Python3Puller): string {.inline.} =
  "__file__"

proc getInstalledPkgs(self: Python3Puller): Future[seq[string]] {.async.} =
  let code = """
        import pkg_resources
        installed_packages = pkg_resources.working_set
        installed_packages_list = sorted(["%s==%s" % (i.key, i.version) for i in installed_packages])
        for pkg in installed_packages_list:
            print(pkg)
"""
  let outputs = await self.client.runPython3Code(code)
  outputs.mapIt(it.getStr)



proc runJavascriptCode(client: LcClient, code: string): Future[JsonNode] {.async.} =
  let titleSlug = "two-sum"
  let questionId = "1"
  let lang = "javascript"
  let code = &"""
var twoSum = function(nums, target) {{
{code}
}}
"""
  let testInput = """
[2,7,11,5]
9
"""
  var res = await client.testSolution(titleSlug, questionId, lang, code, testInput)
  let interpretId = res["interpret_id"].getStr
  res = await client.checkResult(interpretId, false)
  return res["code_output"]

type
  JavascriptPuller = ref object of BasePuller

proc newJavascriptPuller(client: LcClient): JavascriptPuller =
  result.new
  result.client = client

method getFileList(self: JavascriptPuller, dir: string): Future[seq[string]] {.async.} =
  let code = &"""
    const fs = require('fs')
    for (const fn of fs.readdirSync('{dir}')) {{
        console.log(fn)
    }}
"""
  let outputs = await self.client.runJavascriptCode(code)
  return outputs.mapIt(it.getStr)

method getFileContent(self: JavascriptPuller, fn: string): Future[string] {.async.} =
  let code = &"""
    const fs = require('fs')
    let data = fs.readFileSync({fn}, 'base64')
    console.log(data)
"""
  let outputs = await self.client.runJavascriptCode(code)
  let s = outputs.mapIt(it.getStr).join
  return base64.decode(s)

method getDriverFn(self: JavascriptPuller): string {.inline.} =
  "__filename"


const srcDir = "precompiled"

proc pullPrecompiled(client: LcClient, lang: string) {.async.} =
  let puller = case lang
    of "python3":
      newPython3Puller(client)
    of "javascript":
      newJavascriptPuller(client)
    else:
      raise newException(ValueError, "Unsupported language: " & lang)

  let targetDir = "docker" / lang / "precompiled"
  createDir(targetDir)

  block:
    let driverFn = puller.getDriverFn
    let driver = waitFor puller.getFileContent(driverFn)
    writeFile("docker" / lang / "driver", driver)
    sleep(WAIT_INTERVAL)

  for fn in waitFor puller.getFileList(srcDir):
    echo fn
    sleep(WAIT_INTERVAL)
    let data = waitFor puller.getFileContent(&"'{srcDir / fn}'")
    let targetFn = targetDir / fn
    writeFile(targetFn, data)



when isMainModule:
  import ../nlccrcs

  let client = newLcClient()
  client.setToken(nlccrc.getLeetCodeSession)

  when true:
    let lang = "python3"
    # let lang = "javascript"
    waitFor client.pullPrecompiled(lang)

  when false:
    let puller = newPython3Puller(client)
    let pkgs = waitFor puller.getInstalledPkgs
    writeFile("docker" / "python3" / "requirements.txt", pkgs.join("\n"))
