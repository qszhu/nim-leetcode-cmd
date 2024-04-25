import std/[
  os,
  strformat,
  tempfiles,
  times,
]

import db_connector/db_sqlite

import jwts



proc readSessionFromFirefox*(dbFileName: string, host = "leetcode.cn"): JsonWebToken =
  let (_, copyFn) = createTempfile("", ".sqlite")
  writeFile(copyFn, readFile(dbFileName))
  let db = open(copyFn, "", "", "")
  let row = db.getRow(
    sql"SELECT value FROM moz_cookies WHERE host LIKE ? AND name = ?",
    &"%{host}", "LEETCODE_SESSION")
  result = initJWT(row[0])
  db.close
  removeFile(copyFn)

proc getUserName*(jwt: JsonWebToken): string {.inline.} =
  jwt.payload["username"].getStr

proc getExpireTimestamp*(jwt: JsonWebToken): int64 {.inline.} =
  jwt.payload["expired_time_"].getBiggestInt

proc getExpireTime*(jwt: JsonWebToken): string =
  jwt.getExpireTimestamp.fromUnix.format("yyyy-MM-dd HH:mm:ss")
