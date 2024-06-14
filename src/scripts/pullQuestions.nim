import std/[
  strutils,
]

import pkg/nimleetcode



const WAIT_INTERVAL = 10#00

iterator contestList(client: LcClient): JsonNode =
  var page = 1
  while true:
    sleep(WAIT_INTERVAL)
    let res = waitFor client.contestHistory(page)
    let contests = res["data"]["contestHistory"]["contests"]
    if contests.len == 0: break
    for contest in contests: yield contest
    page += 1

iterator contestProblemList(client: LcClient, contestSlug: string): JsonNode =
  sleep(WAIT_INTERVAL)
  let res = waitFor client.contestInfo(contestSlug)
  for question in res["questions"]: yield question

const rootDir = "questions"

when isMainModule:
  import ../nlccrcs

  let client = newLcClient()
  client.setToken(nlccrc.getLeetCodeSession)

  for contest in client.contestList:
    let contestSlug = contest["titleSlug"].getStr
    if not contestSlug.startsWith("weekly-") and not contestSlug.startsWith("biweekly-"): continue

    let dir = rootDir / contestSlug
    createDir(dir)

    for question in client.contestProblemList(contestSlug):
      let titleSlug = question["title_slug"].getStr
      createDir(dir / titleSlug)
      let fn = dir / titleSlug / "source.html"
      echo fn
      if fileExists(fn) and readFile(fn).len > 0: continue

      let res = waitFor client.questionContent(titleSlug)
      let content = res["data"]["question"]["content"].getStr
      if content.len == 0:
        raise newException(CatchableError, "Failed to get question content")

      writeFile(fn, content)
