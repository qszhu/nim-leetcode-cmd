import std/[
  asyncdispatch,
  httpclient,
  json,
  os,
  sequtils,
]



const releaseUrl = "https://api.github.com/repos/qszhu/nim-leetcode-cmd/releases/latest"

when defined windows:
  const targetFn = "nlcc.exe"
else:
  const targetFn = "nlcc"

const downloadFn = "downloaded"

proc upgradeCmd*(): bool =
  let client = newAsyncHttpClient()
  let res = waitFor client.request(releaseUrl, httpMethod = HttpGet)
  let respBody = waitFor res.body
  let jso = respBody.parseJson

  let body = jso["body"].getStr
  echo body

  let name = jso["name"].getStr
  echo "Downloading ", name, "..."

  let asset = jso["assets"].getElems.filterIt(it["name"].getStr == targetFn)[0]
  let downloadUrl = asset["browser_download_url"].getStr
  echo downloadUrl
  waitFor client.downloadFile(downloadUrl, downloadFn)
  if fileExists(targetFn): removeFile(targetFn)
  moveFile(downloadFn, targetFn)
  echo "done"

  true
