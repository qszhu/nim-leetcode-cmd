import std/[
  algorithm,
  json,
  sequtils,
  strformat,
]

import pkg/nimleetcode

import ../../nlccrcs
import ../../projects/projects
import ../../utils
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

proc getContestQuestionPageData(client: LcClient,
  contestSlug, titleSlug: string
): Future[JsonNode] {.async.} =
  let html = await client.getPage(contestSlug, titleSlug)
  return parsePageData(html)

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

  var info = waitFor client.contestInfo(contestSlug)

  let contestInfo = initContestInfo(info["contest"])

  let registered = info["registered"].getBool

  if not contestInfo.isVirtual and not registered:
    echo "Warning: not registered for " & contestInfo.title
    refreshEcho "Registering..."
    waitFor client.register(contestInfo.contestSlug)
    let info = waitFor client.contestInfo(contestSlug)
    let registered = info["registered"].getBool
    if not registered:
      echo "Failed to register for " & contestInfo.title
      return
    else:
      echo "Registered"

  countDown(contestInfo, client)
  info = waitFor client.contestInfo(contestSlug)

  let questions = info["questions"].mapIt(it.initQuestionInfo)

  let langOpt = nlccrc.getLanguageOpt

  for i, q in questions:
    echo &"{i + 1}.{q.title}"
    let res = waitFor client.getContestQuestionPageData(contestSlug, q.titleSlug)
    let snippets = initCodeSnippets(res["codeDefinition"])
    let testInput = res["questionExampleTestcases"].getStr
    let metaData = res["metaData"]
    let proj = initProject(ProjectInfo(
      contestSlug: contestSlug,
      titleSlug: q.titleSlug,
      questionId: $q.questionId,
      lang: langOpt.get,
      order: i + 1,
      testInput: testInput,
      codeSnippets: snippets,
      metaData: metaData,
      problemDesc: res["questionContent"].getStr,
      problemDescEn: res["questionSourceContent"].getStr,
    ))
    proj.initProjectDir

  nlccrc.setCurrentContest(contestSlug)
  nlccrc.setContestQuestions(questions.mapIt(it.titleSlug))
  nlccrc.setContestQuestionTitles(questions.mapIt(it.title))
  nlccrc.setCurrentQuestion(nlccrc.getStartIndex)

  return true
