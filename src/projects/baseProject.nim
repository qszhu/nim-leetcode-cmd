import std/[
  os,
  sequtils,
  strformat,
  strutils,
  tables,
]

import pkg/nimleetcode

import ../nlccrcs
import ../projectrcs
import ../consts
import ../utils

export os, tables, json



type
  ProjectInfo* = object
    titleSlug*: string
    questionId*: string
    lang*: Language
    metaData*: JsonNode

    # in contest
    contestSlug*: string
    order*: int

    # in init
    testInput*: string
    codeSnippets*: Table[string, string]
    problemDesc*, problemDescEn*: string

type
  BaseProject* = ref object of RootObj
    info*: ProjectInfo
    code*: string
    curSolutionFn*: string



method contestSlug*(self: BaseProject): string {.base, inline.} =
  self.info.contestSlug

proc isInContest*(self: BaseProject): bool {.inline.} =
  self.contestSlug.len != 0

method questionSlug*(self: BaseProject): string {.base, inline.} =
  self.info.titleSlug

method init*(self: BaseProject, info: ProjectInfo) {.base, inline.} =
  self.info = info

method submitLang*(self: BaseProject): SubmitLanguage {.base, inline.} =
  raise newException(CatchableError, "Not implemented: submitLang")

method srcFileExt*(self: BaseProject): string {.base, inline.} =
  raise newException(CatchableError, "Not implemented: srcFileExt")

method targetFn*(self: BaseProject): string {.base, inline.} =
  raise newException(CatchableError, "Not implemented: targetFn")

method build*(self: BaseProject): bool {.base.} =
  raise newException(CatchableError, "Not implemented: build")

method localTest*(self: BaseProject) {.base.} =
  raise newException(CatchableError, "Not implemented: localTest")

method debug*(self: BaseProject, port: int) {.base.} =
  raise newException(CatchableError, "Not implemented: debug")

method rootDir*(self: BaseProject): string {.base, inline.} =
  if self.isInContest:
    if self.info.order == 0:
      ROOT_DIR / self.info.contestSlug / self.info.titleSlug / $self.info.lang
    else:
      ROOT_DIR / self.info.contestSlug / &"{self.info.order}.{self.info.titleSlug}" / $self.info.lang
  else:
    QUESTIONS_ROOT_DIR / self.info.titleSlug / $self.info.lang

method srcDir*(self: BaseProject): string {.base, inline.} =
  self.rootDir / "src"

method buildDir*(self: BaseProject): string {.base, inline.} =
  self.rootDir / "build"

method testDir*(self: BaseProject): string {.base, inline.} =
  self.rootDir / ".." / "testCases"

method testInputFn*(self: BaseProject): string {.base, inline.} =
  self.testDir / "input"

method testOutputFn*(self: BaseProject): string {.base, inline.} =
  self.testDir / "output"

method testMyOutputFn*(self: BaseProject): string {.base, inline.} =
  self.testDir / "myoutput"

method appendTestCase*(self: BaseProject, testCase, expected: string) {.base, inline.} =
  block:
    let data = @[readFile(self.testInputFn).strip, testCase].join("\n")
    writeFile(self.testInputFn, data)
  block:
    let data = @[readFile(self.testOutputFn).strip, expected].join("\n")
    writeFile(self.testOutputFn, data)

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
  rc.setQuestionId(self.info.questionId)
  rc.setMetaData(self.info.metaData)

  if not fileExists(self.testInputFn) and self.info.testInput.len > 0:
    writeFile(self.testInputFn, self.info.testInput)
  if not fileExists(self.testOutputFn):
    let output = extractOutput(self.info.problemDescEn)
    writeFile(self.testOutputFn, output)
  var srcFn = rc.getCurrentSrc
  if srcFn.len == 0: srcFn = self.getNextSolutionFn
  if not fileExists(srcFn):
    writeFile(srcFn, self.code)
  self.curSolutionFn = srcFn
  rc.setCurrentSrc(srcFn)

proc showSubmissionState*(jso: JsonNode) =
  let state = jso["state"].getStr
  refreshEcho state

proc checkResult*(client: LcClient, submitId: string, isTest: bool): Future[JsonNode] {.async.} =
  while true:
    let res = await client.checkSubmissionResult(submitId, isTest)
    if "status_msg" notin res:
      showSubmissionState(res)
    else:
      echo ""
      return res
    await sleepAsync(1000)

method test*(self: BaseProject, client: LcClient): JsonNode {.base.} =
  let code = readFile(self.targetFn)
  let testInput = readFile(self.testInputFn)
  if self.isInContest:
    result = waitFor client.testContestSolution(
      self.info.contestSlug, self.info.titleSlug, self.info.questionId, $self.submitLang, code, testInput)
  else:
    result = waitFor client.testSolution(
      self.info.titleSlug, self.info.questionId, $self.submitLang, code, testInput)
  let interpretId = result["interpret_id"].getStr
  result = waitFor client.checkResult(interpretId, isTest = true)

method submit*(self: BaseProject, client: LcClient): JsonNode {.base.} =
  let code = readFile(self.targetFn)
  if self.isInContest:
    result = waitFor client.submitContestSolution(
      self.info.contestSlug, self.info.titleSlug, self.info.questionId, $self.submitLang, code)
  else:
    result = waitFor client.submitSolution(
      self.info.titleSlug, self.info.questionId, $self.submitLang, code)
  let submitId = $(result["submission_id"].getBiggestInt)
  result = waitFor client.checkResult(submitId, isTest = false)

method initFromProject*(self: BaseProject, contestSlug, titleSlug: string, lang: Language, currentQuestion: int) {.base.} =
  let order = currentQuestion + 1
  let dir = ROOT_DIR / contestSlug / &"{order}.{titleSlug}" / $lang
  let rc = initProjectRC(dir)
  self.init(ProjectInfo(
    contestSlug: contestSlug,
    titleSlug: titleSlug,
    questionId: rc.getQuestionId,
    lang: lang,
    order: order,
    metaData: rc.getMetaData,
  ))
  self.curSolutionFn = rc.getCurrentSrc

method initFromProject*(self: BaseProject, questionSlug: string, lang: Language) {.base.} =
  let dir = QUESTIONS_ROOT_DIR / questionSlug / $lang
  let rc = initProjectRC(dir)
  self.init(ProjectInfo(
    titleSlug: questionSlug,
    questionId: rc.getQuestionId,
    lang: lang,
    metaData: rc.getMetaData,
  ))
  self.curSolutionFn = rc.getCurrentSrc
