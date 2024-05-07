import ../../lib/leetcode/[lcClient, utils]
import ../../nlccrcs
import ../../projects/projects



import std/[json, sequtils, tables]

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
  of "nim":
    initNimProject(info)
  else:
    raise newException(ValueError, "Unsupported language: " & info.lang)

proc start*(contestSlugOrUrl: string): bool =
  let contestSlug = getContestSlug(contestSlugOrUrl)

  let client = newLcClient()
  client.setToken(nlccrc.getLeetCodeSession)

  let info = waitFor client.contestInfo(contestSlug)

  let contestInfo = initContestInfo(info["contest"])
  let questions = info["questions"].mapIt(it.initQuestionInfo)

  let registered = info["registered"].getBool
  if not contestInfo.isVirtual and not registered:
    echo "Warning: not registered for contest"
    # TODO: register for contest

  let lang = nlccrc.getLanguage

  for q in questions:
    var res = waitFor client.questionEditorData(q.titleSlug)
    let snippets = initCodeSnippets(res["data"]["question"]["codeSnippets"])

    res = waitFor client.consolePanelConfig(q.titleSlug)
    let testInput = res["data"]["question"]["exampleTestcases"].getStr
    let metaData = res["data"]["question"]["metaData"].getStr

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

  return true
