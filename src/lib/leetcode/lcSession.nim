import std/[
  os,
  strutils,
  times,
]

import ../jwts
import session/[chrome, firefox]

export jwts



proc getDefaultChromeProfilePath*(): string {.inline.} =
  # TODO: other oses
  getEnv("HOME") / "Library" / "Application Support" / "Google" / "Chrome" / "Default"

proc readSession*(browser, profilePath: string): JsonWebToken =
  case browser.toLowerAscii
  of "firefox":
    let dbFn = profilePath / "cookies.sqlite"
    initJWT(readSessionFromFirefox(dbFn))
  of "chrome":
    let dbFn = profilePath / "Cookies"
    initJWT(readSessionFromChrome(dbFn))
  else:
    raise newException(ValueError, "Unsupported browser: " & browser)

proc getUserName*(jwt: JsonWebToken): string {.inline.} =
  jwt.payload["username"].getStr

proc getExpireTimestamp*(jwt: JsonWebToken): int64 {.inline.} =
  jwt.payload["expired_time_"].getBiggestInt

proc getExpireTime*(jwt: JsonWebToken): string =
  jwt.getExpireTimestamp.fromUnix.format("yyyy-MM-dd HH:mm:ss")
