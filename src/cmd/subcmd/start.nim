import std/[
  algorithm,
  json,
  sequtils,
  tables,
]

import ../../lib/leetcode/lcClient
import ../../nlccrcs
import ../../projects/projects
import ../../consts



type
  ContestInfo = object
    startTimestampInSec: int64
    durationInSec: int
    isVirtual: bool

proc initContestInfo(jso: JsonNode): ContestInfo =
  ContestInfo(
    startTimestampInSec: jso["start_time"].getBiggestInt,
    durationInSec: jso["duration"].getInt,
    isVirtual: jso["is_virtual"].getBool
  )

type
  QuestionInfo = object
    questionId: int
    title: string
    credit: int
    titleSlug: string

proc initQuestionInfo(jso: JsonNode): QuestionInfo =
  QuestionInfo(
    questionId: jso["question_id"].getInt,
    title: jso["title"].getStr,
    credit: jso["credit"].getInt,
    titleSlug: jso["title_slug"].getStr,
  )

type
  CodeSnippets = Table[string, string]

proc initCodeSnippets(jso: JsonNode): CodeSnippets =
  for r in jso:
    result[r["langSlug"].getStr] = r["code"].getStr



proc initProject(info: ProjectInfo): BaseProject =
  case info.lang
  of LANG_NIM_JS:
    initNimJsProject(info)
  else:
    raise newException(ValueError, "Unsupported language: " & info.lang)

proc getQuestionCodeSnippets(client: LcClient, titleSlug: string): Future[CodeSnippets] {.async.} =
  let res = await client.questionEditorData(titleSlug)
  initCodeSnippets(res["data"]["question"]["codeSnippets"])

proc getQuestionTestCasesAndMeta(client: LcClient, titleSlug: string): Future[(string, JsonNode)] {.async.} =
  let res = await client.consolePanelConfig(titleSlug)
  let testInput = res["data"]["question"]["exampleTestcases"].getStr
  let metaData = res["data"]["question"]["metaData"].getStr.parseJson
  (testInput, metaData)

proc startCmd*(contestSlug: string): bool =
  let client = newLcClient()
  client.setToken(nlccrc.getLeetCodeSession)

  let info = waitFor client.contestInfo(contestSlug)

  let contestInfo = initContestInfo(info["contest"])
  let questions = info["questions"].mapIt(it.initQuestionInfo).sortedByIt(it.credit)

  let registered = info["registered"].getBool
  if not contestInfo.isVirtual and not registered:
    echo "Warning: not registered for contest"
    # TODO: register for contest

  let lang = nlccrc.getLanguage

  for q in questions:
    let snippets = waitFor client.getQuestionCodeSnippets(q.titleSlug)
    let (testInput, metaData) = waitFor client.getQuestionTestCasesAndMeta(q.titleSlug)
    let proj = initProject(ProjectInfo(
      contestSlug: contestSlug,
      titleSlug: q.titleSlug,
      questionId: $q.questionId,
      lang: lang,
      testInput: testInput,
      codeSnippets: snippets,
      metaData: metaData,
    ))
    proj.initProjectDir

  nlccrc.setContestQuestions(questions.mapIt(it.titleSlug))
  nlccrc.setCurrentQuestion(0)

  return true
