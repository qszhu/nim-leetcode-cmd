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

export os



const ROOT = "contests"
const TMPL_VAR_SOLUTION_SRC = "{{solutionSrc}}"

type
  ProjectInfo* = object
    contestSlug*: string
    titleSlug*: string
    questionId*: string

    lang*: string
    testInput*: string
    codeSnippets*: Table[string, string]
    metaData*: string

type
  BaseProject* = ref object of RootObj
    info*: ProjectInfo
    code*: string
    curSolutionFn*: string



method init*(self: BaseProject, info: ProjectInfo) {.base.} =
  self.info = info

method srcFileExt*(self: BaseProject): string {.base.} =
  raise newException(CatchableError, "Not implemented")

method targetFn*(self: BaseProject): string {.base.} =
  raise newException(CatchableError, "Not implemented")

method build*(self: BaseProject) {.base.} =
  raise newException(CatchableError, "Not implemented")

method rootDir*(self: BaseProject): string {.base.} =
  ROOT / self.info.contestSlug / self.info.titleSlug / self.info.lang

method srcDir*(self: BaseProject): string {.base.} =
  self.rootDir / "src"

method buildDir*(self: BaseProject): string {.base.} =
  self.rootDir / "build"

method testDir*(self: BaseProject): string {.base.} =
  self.rootDir / "testCases"

method testInputFn*(self: BaseProject): string {.base.} =
  self.testDir / "input"

method getNextSolutionFn*(self: BaseProject): string {.base.} =
  let n = walkFiles(self.srcDir / &"solution*.{self.srcFileExt}").toSeq.len + 1
  self.srcDir / &"solution{n}.{self.srcFileExt}"

method openInEditor*(self: BaseProject) {.base.} =
  let editorCmd = nlccrc.getEditorCmd
  if editorCmd.len == 0: return
  let cmd = editorCmd.replace(TMPL_VAR_SOLUTION_SRC, self.curSolutionFn)
  discard execShellCmd(cmd)

method initProjectDir*(self: BaseProject) {.base.} =
  createDir(self.srcDir)
  createDir(self.buildDir)
  createDir(self.testDir)

  let rc = initProjectRC(self.rootDir)
  rc.setContestSlug(self.info.contestSlug)
  rc.setQuestionSlug(self.info.titleSlug)
  rc.setQuestionId(self.info.questionId)

  if not fileExists(self.testInputFn) and self.info.testInput.len > 0:
    writeFile(self.testInputFn, self.info.testInput)
  if self.code.len > 0:
    let srcFn = self.getNextSolutionFn
    writeFile(srcFn, self.code)
    self.curSolutionFn = srcFn
    rc.setCurrentSrc(srcFn)
    self.openInEditor

method test*(self: BaseProject, client: LcClient) {.base.} =
  let code = readFile(self.curSolutionFn)
  let testInput = readFile(self.testInputFn)
  let res = waitFor client.testContestSolution(
    self.info.contestSlug, self.info.titleSlug, self.info.questionId, self.info.lang, code, testInput)

method submit*(self: BaseProject, client: LcClient) {.base.} =
  let code = readFile(self.curSolutionFn)
  let res = waitFor client.submitContestSolution(
    self.info.contestSlug, self.info.titleSlug, self.info.questionId, self.info.lang, code)

method initFromDir*(self: BaseProject, dir: string) {.base.} =
  let rc = initProjectRC(self.rootDir)
  self.init(ProjectInfo(
    contestSlug: rc.getContestSlug,
    titleSlug: rc.getQuestionSlug,
    questionId: rc.getQuestionId,
  ))
  self.curSolutionFn = rc.getCurrentSrc
