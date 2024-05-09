import std/[
  os,
  sequtils,
  strformat,
  strutils,
  uri,
]

import consts



proc refreshEcho*(msg: string) =
  stdout.write &"\r{msg}" & " ".repeat(10)
  stdout.flushFile

proc getContestSlug*(s: string): string =
  if not s.startsWith("http"): return s
  let res = s.parseUri
  res.path.split("/").filterIt(it.len > 0)[^1]

proc getQuestionUrl*(contestSlug, questionSlug: string, host = "https://leetcode.cn"): Uri {.inline.} =
  host.parseUri / "contest" / contestSlug / "problems" / (questionSlug & "/")

proc openUrlInBrowser*(browser: Browser, uri: Uri) =
  # TODO: other oses
  let cmd =
    case browser
    of Browser.CHROME:
      &"open -a \"Google Chrome.app\" {uri}"
    else:
      raise newException(ValueError, "Unsupported browser: " & $browser)
  discard execShellCmd(cmd)



when isMainModule:
  doAssert getContestSlug("") == ""
  doAssert getContestSlug("weekly-contest-396") == "weekly-contest-396"
  doAssert getContestSlug("https://leetcode.cn/contest/weekly-contest-396/") == "weekly-contest-396"
  doAssert getContestSlug("https://leetcode.cn/contest/weekly-contest-396") == "weekly-contest-396"
  doAssert getContestSlug("weekly-contest-396") == "weekly-contest-396"
  doAssert getContestSlug("https://leetcode.cn/contest/biweekly-contest-129/") == "biweekly-contest-129"
