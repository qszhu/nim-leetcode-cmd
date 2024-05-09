import std/[
  os,
  times,
]

import ../jwts
import session/[chrome, firefox]
import ../../consts

export jwts



proc getDefaultChromeProfilePath*(): string {.inline.} =
  # TODO: other oses
  getEnv("HOME") / "Library" / "Application Support" / "Google" / "Chrome" / "Default"

proc readSession*(browser: Browser, profilePath: string): JsonWebToken =
  case browser
  of Browser.FIREFOX:
    let dbFn = profilePath / "cookies.sqlite"
    initJWT(readSessionFromFirefox(dbFn))
  of Browser.CHROME:
    let dbFn = profilePath / "Cookies"
    initJWT(readSessionFromChrome(dbFn))

proc getUserName*(jwt: JsonWebToken): string {.inline.} =
  jwt.payload["username"].getStr

proc getExpireTimestamp*(jwt: JsonWebToken): int64 {.inline.} =
  jwt.payload["expired_time_"].getBiggestInt

proc getExpireTime*(jwt: JsonWebToken): string =
  jwt.getExpireTimestamp.fromUnix.format("yyyy-MM-dd HH:mm:ss")
