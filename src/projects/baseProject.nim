import std/[
  os,
  sequtils,
  strformat,
  strutils,
  tables,
]

import ../lib/leetcode/lcClient
import ../nlccrcs
import ../projectrcs
import ../consts
import ../utils

export os



type
  ProjectInfo* = object
    contestSlug*: string
    titleSlug*: string
    questionId*: string
    lang*: Language

    testInput*: string
    codeSnippets*: Table[string, string]
    metaData*: JsonNode

type
  BaseProject* = ref object of RootObj
    info*: ProjectInfo
    code*: string
    curSolutionFn*: string



method contestSlug*(self: BaseProject): string {.base, inline.} =
  self.info.contestSlug

method questionSlug*(self: BaseProject): string {.base, inline.} =
  self.info.titleSlug

method init*(self: BaseProject, info: ProjectInfo) {.base, inline.} =
  self.info = info

method submitLang*(self: BaseProject): SubmitLanguage {.base, inline.} =
  raise newException(CatchableError, "Not implemented")

method srcFileExt*(self: BaseProject): string {.base, inline.} =
  raise newException(CatchableError, "Not implemented")

method targetFn*(self: BaseProject): string {.base, inline.} =
  raise newException(CatchableError, "Not implemented")

method build*(self: BaseProject): bool {.base, inline.} =
  raise newException(CatchableError, "Not implemented")

method rootDir*(self: BaseProject): string {.base, inline.} =
  ROOT_DIR / self.info.contestSlug / self.info.titleSlug / $self.info.lang

method srcDir*(self: BaseProject): string {.base, inline.} =
  self.rootDir / "src"

method buildDir*(self: BaseProject): string {.base, inline.} =
  self.rootDir / "build"

method testDir*(self: BaseProject): string {.base, inline.} =
  self.rootDir / "testCases"

method testInputFn*(self: BaseProject): string {.base, inline.} =
  self.testDir / "input"

method testOutputFn*(self: BaseProject): string {.base, inline.} =
  self.testDir / "output"

method testMyOutputFn*(self: BaseProject): string {.base, inline.} =
  self.testDir / "myoutput"

method appendTestCase*(self: BaseProject, testCase: string) {.base, inline.} =
  let data = @[readFile(self.testInputFn), testCase].join("\n")
  writeFile(self.testInputFn, data)

method getNextSolutionFn*(self: BaseProject): string {.base.} =
  let n = walkFiles(self.srcDir / &"solution*.{self.srcFileExt}").toSeq.len + 1
  self.srcDir / &"solution{n}.{self.srcFileExt}"

method openInEditor*(self: BaseProject, fn = "") {.base.} =
  let editorCmd = nlccrc.getEditorCmd
  if editorCmd.len == 0: return
  let fn = if fn.len == 0: self.curSolutionFn else: fn
  let cmd = editorCmd.replace(TMPL_VAR_SOLUTION_SRC, fn)
  discard execShellCmd(cmd)

method initProjectDir*(self: BaseProject) {.base.} =
  createDir(self.srcDir)
  createDir(self.buildDir)
  createDir(self.testDir)

  let rc = initProjectRC(self.rootDir)
  # rc.setContestSlug(self.info.contestSlug)
  # rc.setQuestionSlug(self.info.titleSlug)
  rc.setQuestionId(self.info.questionId)

  if not fileExists(self.testInputFn) and self.info.testInput.len > 0:
    writeFile(self.testInputFn, self.info.testInput)
  if self.code.len > 0:
    let srcFn = self.getNextSolutionFn
    writeFile(srcFn, self.code)
    self.curSolutionFn = srcFn
    rc.setCurrentSrc(srcFn)

proc showSubmissionState*(jso: JsonNode) =
  let state = jso["state"].getStr
  refreshEcho state

proc checkResult(client: LcClient, submitId: string, isTest: bool): Future[JsonNode] {.async.} =
  while true:
    let res = await client.checkSubmissionResult(submitId, isTest)
    if "status_msg" notin res:
      showSubmissionState(res)
    else:
      return res
    await sleepAsync(1000)

method test*(self: BaseProject, client: LcClient): JsonNode {.base.} =
  let code = readFile(self.targetFn)
  let testInput = readFile(self.testInputFn)
  result = waitFor client.testContestSolution(
    self.info.contestSlug, self.info.titleSlug, self.info.questionId, $self.submitLang, code, testInput)
  let interpretId = result["interpret_id"].getStr
  result = waitFor client.checkResult(interpretId, isTest = true)

method submit*(self: BaseProject, client: LcClient): JsonNode {.base.} =
  let code = readFile(self.targetFn)
  result = waitFor client.submitContestSolution(
    self.info.contestSlug, self.info.titleSlug, self.info.questionId, $self.submitLang, code)
  let submitId = $(result["submission_id"].getBiggestInt)
  result = waitFor client.checkResult(submitId, isTest = false)

method initFromProject*(self: BaseProject, contestSlug, titleSlug: string, lang: Language) {.base.} =
  let dir = ROOT_DIR / contestSlug / titleSlug / $lang
  let rc = initProjectRC(dir)
  self.init(ProjectInfo(
    contestSlug: contestSlug,
    titleSlug: titleSlug,
    questionId: rc.getQuestionId,
    lang: lang,
  ))
  self.curSolutionFn = rc.getCurrentSrc
