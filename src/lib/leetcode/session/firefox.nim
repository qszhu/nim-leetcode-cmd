import std/[
  os,
  strformat,
  tempfiles,
]

import db_connector/db_sqlite



proc readSessionFromFirefox*(dbFileName: string, host = "leetcode.cn"): string =
  let (_, copyFn) = createTempfile("", ".sqlite")
  try:
    writeFile(copyFn, readFile(dbFileName))
    let db = open(copyFn, "", "", "")
    let row = db.getRow(
      sql"SELECT value FROM moz_cookies WHERE host LIKE ? AND name = ?",
      &"%{host}", "LEETCODE_SESSION")
    result = row[0]
    db.close
  finally:
    removeFile(copyFn)
