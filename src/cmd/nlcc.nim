import std/[
  logging,
  sequtils,
  strformat,
  strutils,
  times,
]

import pkg/[nimbrowsercookies, nimleetcode]

import ../lib/[args, prompts]
import ../nlccrcs
import ../consts
import ../projects/projects
import ../utils
import consts
import subcmd/[build, debug, start, submit, sync, test, upgrade]



const SESSION_EXPIRE_WARNING_SECS = 7 * 24 * 60 * 60

const VERSION = "0.8.2"

proc showVersion() =
  echo VERSION

proc showHelp() =
  echo """
nlcc
  start                           start current running contest or count down for upcoming contest
    [contest slug]                start contest with contest slug (e.g. weekly-contest-400)
    [contest url]                 start contest with contest url
  test                            test current solution
    [-l]                          test current solution locally
  build                           build current solution
  submit                          submit current solution
  next                            open next question in the contest
  list                            list questions in the contest and select one to open
  select <n>                      select specified question in the contest to open
  startIdx <n>                    set first question to open in a contest
  lang                            change programming language to solve questions
  sync                            sync sessions from browser
    [-f]                          force sync sessions from a new browser
  upgrade                         download the latest release
  verbose <0|1>                   verbose mode
  version                         show version
  help                            show help
"""

proc initCurrentProject(): BaseProject
proc openCurrent(): bool

proc sync0(): bool =
  let args = initArgs()
    .addOption(OPT_FORCE, "f")
    .parse

  let force = args.hasOption(OPT_FORCE)

  var browserOpt = if force: none(Browser) else: nlccrc.getBrowserOpt
  if browserOpt.isNone:
    var browser: string
    if not prompt("Choose browser", browser,
      choices = Browser.toSeq.mapIt($it), default = $Browser.CHROME): return

    try:
      browserOpt = some(parseEnum[Browser](browser))
    except:
      return

  var profilePath = if force: "" else: nlccrc.getBrowserProfilePath
  if profilePath.len == 0:
    let default = case browserOpt.get
      of Browser.CHROME: getChromeDefaultProfilePath()
      of Browser.EDGE: getEdgeDefaultProfilePath()
      else: ""
    if not prompt("Browser profile path", profilePath, default): return

  if not syncCmd(browserOpt.get, profilePath): return

  nlccrc.setBrowser(browserOpt.get)
  nlccrc.setBrowserProfilePath(profilePath)

  let lcSession = initJWT(nlccrc.getLeetCodeSession)
  echo &"Sync complete. Session now expires at {lcSession.getExpireTime}."
  true

proc start0(): bool =
  let args = initArgs().parse

  var contestSlug = args.getArg(1).getContestSlug

  if not startCmd(contestSlug): return

  if contestSlug.len > 0:
    nlccrc.setCurrentContest(contestSlug)
  openCurrent()

proc build0(): bool =
  let proj = initCurrentProject()
  buildCmd(proj)

proc test0(): bool =
  let args = initArgs()
    .addOption(OPT_LOCAL, "l")
    .parse

  let local = args.hasOption(OPT_LOCAL)

  let proj = initCurrentProject()
  testCmd(proj, local)

proc debug0(): bool =
  let args = initArgs()
    .addOption(OPT_DEBUG_PORT, "p")
    .parse

  let port = args.getOption(OPT_DEBUG_PORT, "5678").parseInt

  let proj = initCurrentProject()
  debugCmd(proj, port)

proc next0(): bool =
  let questions = nlccrc.getContestQuestions
  let cur = nlccrc.getCurrentQuestion
  let next = (cur + 1) mod questions.len
  nlccrc.setCurrentQuestion(next)

  openCurrent()

proc submit0(): bool =
  let proj = initCurrentProject()
  if not submitCmd(proj): return

  next0()

proc select0(): bool =
  let args = initArgs().parse

  let questions = nlccrc.getContestQuestions
  var num = args.getArg(1)
  if num.len == 0:
    if not prompt(&"Question no [1..{questions.len}]", num): return

  let n = num.parseInt - 1
  if n notin 0 ..< questions.len: return

  nlccrc.setCurrentQuestion(n)

  openCurrent()

proc list0(): bool =
  let titles = nlccrc.getContestQuestionTitles
  for i, title in titles:
    echo &"{i + 1}.{title}"
  select0()

proc startIdx0(): bool =
  var s: string
  if not prompt(&"Default start question index [1..4]", s): return
  let n = s.parseInt
  if n notin 1 .. 4: return
  nlccrc.setStartIndex(n - 1)

proc lang0(): bool =
  var lang: string
  if not prompt("Choose language", lang,
    choices = Language.toSeq.mapIt($it)): return

  try:
    nlccrc.setLanguage(parseEnum[Language](lang))
  except:
    echo "Unknown language: " & lang
    return
  true

proc upgrade0(): bool =
  upgradeCmd()

proc verbose0(): bool =
  let args = initArgs().parse
  if args.getArg(1).len == 0 or args.getArg(1).parseInt != 0:
    echo "verbose: true"
    nlccrc.setVerbose(true)
  else:
    echo "verbose: false"
    nlccrc.setVerbose(false)

proc initCurrentProject(): BaseProject =
  let contestSlug = nlccrc.getCurrentContest
  let questionSlug = nlccrc.getContestQuestions[nlccrc.getCurrentQuestion]
  let langOpt = nlccrc.getLanguageOpt
  let lang = langOpt.get
  case lang
  of Language.NIM_JS:
    result = NimJsProject.new
  of Language.NIM_WASM:
    result = NimWasmProject.new
  of Language.PYTHON3:
    result = Python3Project.new
  result.initFromProject(contestSlug, questionSlug, lang, nlccrc.getCurrentQuestion)

proc openCurrent(): bool =
  let proj = initCurrentProject()
  proj.openInEditor

  let browserOpt = nlccrc.getBrowserOpt
  if browserOpt.isNone: return

  openUrlInBrowser(browserOpt.get, getContestQuestionUrl(proj.contestSlug, proj.questionSlug))

  true

proc check(): bool =
  let verbose = nlccrc.getVerbose
  if verbose or defined(debug):
    addHandler(newConsoleLogger(levelThreshold = lvlDebug))
  else:
    addHandler(newConsoleLogger(levelThreshold = lvlNotice))

  var session = nlccrc.getLeetCodeSession
  if session.len == 0:
    if not sync0(): return
    session = nlccrc.getLeetCodeSession
  if session.len == 0: return

  let lcSession = initJWT(session)
  let sessionRemainTime = lcSession.getExpireTimestamp - getTime().toUnix
  if sessionRemainTime <= SESSION_EXPIRE_WARNING_SECS:
    echo &"Warning: session expires at {lcSession.getExpireTime}. Consider refreshing session (logout and login again) in the browser and run \"nlcc sync\"."
  elif sessionRemainTime <= 0:
    echo &"Session expired at {lcSession.getExpireTime}."
    return

  let langOpt = nlccrc.getLanguageOpt
  if langOpt.isNone:
    if not lang0(): return

  true

proc main(): int =
  if not check(): return -1

  let args = initArgs().parse

  case args.getArg(0)
  of CMD_SYNC:
    if not sync0(): return -1
  of CMD_BUILD:
    if not build0(): return -1
  of CMD_TEST:
    if not build0(): return -1
    if not test0(): return -1
  of CMD_DEBUG:
    if not build0(): return -1
    if not debug0(): return -1
  of CMD_SUBMIT:
    if not build0(): return -1
    if not submit0(): return -1
  of CMD_NEXT:
    if not next0(): return -1
  of CMD_SELECT:
    if not select0(): return -1
  of CMD_START_IDX:
    if not startIdx0(): return -1
  of CMD_LANG:
    if not lang0(): return -1
  of CMD_LIST:
    if not list0(): return -1
  of CMD_UPGRADE:
    if not upgrade0(): return -1
  of CMD_START:
    if not start0(): return -1
  # TODO: custom editor command
  # TODO: custom diff command
  of CMD_VERBOSE:
    if not verbose0(): return -1
  of CMD_VERSION:
    showVersion()
  else:
    showHelp()



when isMainModule:
  quit(main())
