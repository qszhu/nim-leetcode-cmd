import std/[
  sequtils,
  strutils,
  uri,
]



proc getContestSlug*(s: string): string =
  if not s.startsWith("http"): return s
  let res = s.parseUri
  res.path.split("/").filterIt(it.len > 0)[^1]



when isMainModule:
  doAssert getContestSlug("https://leetcode.cn/contest/weekly-contest-396/") == "weekly-contest-396"
  doAssert getContestSlug("https://leetcode.cn/contest/weekly-contest-396") == "weekly-contest-396"
  doAssert getContestSlug("weekly-contest-396") == "weekly-contest-396"
  doAssert getContestSlug("https://leetcode.cn/contest/biweekly-contest-129/") == "biweekly-contest-129"
