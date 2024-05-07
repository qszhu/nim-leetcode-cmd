# https://n8henrie.com/2014/05/decrypt-chrome-cookies-with-python/
import std/[
  osproc,
  strformat,
  strutils,
]

import db_connector/db_sqlite

import ../../crypto



proc getChromePassword(): string =
  # TODO: native implementation
  let cmd = "security find-generic-password -w -s \"Chrome Safe Storage\""
  execProcess(cmd).strip

proc readSessionFromChrome*(dbFileName: string, host = "leetcode.cn"): string =
  let db = open(dbFileName, "", "", "")
  let row = db.getRow(
    sql"SELECT encrypted_value FROM cookies WHERE host_key LIKE ? and name = ?",
    &"%{host}", "LEETCODE_SESSION"
  )
  db.close

  let encrypted = row[0][3 .. ^1]

  # TODO: other oses
  const salt = "saltysalt"
  const keyLen = 16
  const iterations = 1003

  let pass = getChromePassword()
  if pass.len == 0:
    raise newException(ValueError, "Failed to get chrome password")

  let key = pbkdf2(pass, salt, iterations, keyLen)

  let iv = " ".repeat(keyLen)
  result = decrypt(encrypted, key, iv)
