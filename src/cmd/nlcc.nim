#[
* sync
  * firefox [profile_path]
  * chrome [cookies_db_path]
* start <contest_slug | url>
* new <problem_slug | n>
* build <problem_slug | n>
* test <problem_slug | n>
* submit <problem_slug | n>
* next
* rank
]#
import std/[
  strformat,
  strutils,
  times,
]

import ../lib/[args, prompts]
import ../lib/leetcode/lcSession
import ../nlccrcs
import consts
import subcmd/[start, sync]



const SESSION_EXPIRE_WARNING_SECS = 3 * 24 * 60 * 60

proc showHelp(): int = discard

proc sync0(): bool =
  let args = initArgs()
    .addOption(OPT_FORCE, "f")
    .parse

  let force = args.getOption(OPT_FORCE) == "1"

  var browser = if force: "" else: nlccrc.getBrowser
  if browser.len == 0:
    if not prompt("Choose browser", browser, default = "chrome"): return

  var profilePath = if force: "" else: nlccrc.getBrowserProfilePath
  if profilePath.len == 0:
    let default = if browser.toLowerAscii == "chrome": getDefaultChromeProfilePath() else: ""
    if not prompt("Browser profile path", profilePath, default): return

  if not sync(browser, profilePath): return

  nlccrc.setBrowser(browser)
  nlccrc.setBrowserProfilePath(profilePath)

  true

proc start0(): bool =
  let args = initArgs().parse

  var contestSlugOrUrl = args.getArg(1)
  if contestSlugOrUrl.len == 0:
    contestSlugOrUrl = nlccrc.getCurrentContest
  if contestSlugOrUrl.len == 0:
    if not prompt("Contest slug or url", contestSlugOrUrl): return

  if start(contestSlugOrUrl):
    nlccrc.setCurrentContest(contestSlugOrUrl)

  true

proc check(): bool =
  var session = nlccrc.getLeetCodeSession
  if session.len == 0:
    if not sync0(): return
    session = nlccrc.getLeetCodeSession
  if session.len == 0: return

  let lcSession = initJWT(session)
  if lcSession.getExpireTimestamp - getTime().toUnix <= SESSION_EXPIRE_WARNING_SECS:
    echo &"Warning: Session expires at {lcSession.getExpireTime}. Consider refresh session in the browser and run \"nlcc sync\" again."

  var lang = nlccrc.getLanguage
  if lang.len == 0:
    if not prompt("Choose language", lang): return
    nlccrc.setLanguage(lang)

  true

proc main(): int =
  if not check(): return -1

  let args = initArgs().parse

  case args.getArg(0)
  of CMD_SYNC:
    if not sync0(): return -1
  of CMD_START:
    if not start0(): return -1
  else:
    return showHelp()



when isMainModule:
  quit(main())
