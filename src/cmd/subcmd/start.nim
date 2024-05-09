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
import utils



type
  ContestInfo = object
    startTimestampInSec: int64
    durationInSec: int
    isVirtual: bool
    title: string
    contestSlug: string

proc initContestInfo(jso: JsonNode): ContestInfo =
  ContestInfo(
    startTimestampInSec: jso["start_time"].getBiggestInt,
    durationInSec: jso["duration"].getInt,
    isVirtual: jso["is_virtual"].getBool,
    title: jso["title"].getStr,
    contestSlug: jso["title_slug"].getStr,
  )

type
  UpcomingContest = object
    contestSlug: string
    startTimestampInSec: int64
    isVirtual: bool

proc initUpcomingContest(jso: JsonNode): UpcomingContest =
  UpcomingContest(
    startTimestampInSec: jso["startTime"].getBiggestInt,
    isVirtual: jso["isVirtual"].getBool,
    contestSlug: jso["titleSlug"].getStr,
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
  of Language.NIM_JS:
    initNimJsProject(info)
  else:
    raise newException(ValueError, "Unsupported language: " & $info.lang)

proc getQuestionCodeSnippets(client: LcClient, titleSlug: string): Future[CodeSnippets] {.async.} =
  let res = await client.questionEditorData(titleSlug)
  initCodeSnippets(res["data"]["question"]["codeSnippets"])

proc getQuestionTestCasesAndMeta(client: LcClient, titleSlug: string): Future[(string, JsonNode)] {.async.} =
  let res = await client.consolePanelConfig(titleSlug)
  let testInput = res["data"]["question"]["exampleTestcases"].getStr
  let metaData = res["data"]["question"]["metaData"].getStr.parseJson
  (testInput, metaData)

proc countDown(contest: ContestInfo, client: LcClient) =
  echo contest.title
  while true:
    var res = waitFor client.timestamp
    let nowInSec = res["timestamp"].getFloat
    let delta = contest.startTimestampInSec.float - nowInSec
    if delta <= 0: break
    showCountDown(delta)
    sleep(1000)

proc startCmd*(contestSlug: string): bool =
  var contestSlug = contestSlug

  let client = newLcClient()
  client.setToken(nlccrc.getLeetCodeSession)

  if contestSlug.len == 0:
    let res = waitFor client.contestUpcomingContests()
    let upcomingContests = res["data"]["contestUpcomingContests"]
      .mapIt(it.initUpcomingContest)
      .filterIt(not it.isVirtual)
      .sortedByIt(it.startTimestampInSec)
    if upcomingContests.len == 0: return

    let nextContest = upcomingContests[0]
    contestSlug = nextContest.contestSlug

  let info = waitFor client.contestInfo(contestSlug)

  let contestInfo = initContestInfo(info["contest"])

  let registered = info["registered"].getBool

  if not contestInfo.isVirtual and not registered:
    echo "Warning: not registered for " & contestInfo.title
    stdout.write "Registering..."
    stdout.flushFile
    waitFor client.register(contestInfo.contestSlug)
    let info = waitFor client.contestInfo(contestSlug)
    let registered = info["registered"].getBool
    if not registered:
      echo "Failed to register for " & contestInfo.title
      return
    else:
      echo "Registered"

  countDown(contestInfo, client)

  let questions = info["questions"].mapIt(it.initQuestionInfo).sortedByIt(it.credit)


  let langOpt = nlccrc.getLanguageOpt

  for q in questions:
    let snippets = waitFor client.getQuestionCodeSnippets(q.titleSlug)
    let (testInput, metaData) = waitFor client.getQuestionTestCasesAndMeta(q.titleSlug)
    let proj = initProject(ProjectInfo(
      contestSlug: contestSlug,
      titleSlug: q.titleSlug,
      questionId: $q.questionId,
      lang: langOpt.get,
      testInput: testInput,
      codeSnippets: snippets,
      metaData: metaData,
    ))
    proj.initProjectDir

  nlccrc.setContestQuestions(questions.mapIt(it.titleSlug))
  # TODO: custom start index
  nlccrc.setCurrentQuestion(0)

  return true
