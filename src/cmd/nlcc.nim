import std/[
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
import subcmd/[start, sync, build, test, submit]



const SESSION_EXPIRE_WARNING_SECS = 7 * 24 * 60 * 60

proc showHelp(): int = discard
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

  true

proc start0(): bool =
  let args = initArgs().parse

  var contestSlug = args.getArg(1).getContestSlug

  if not startCmd(contestSlug): return

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
    if not prompt(&"Question no [1..{questions.len}]:", num): return

  let n = num.parseInt - 1
  if n notin 0 ..< questions.len: return

  nlccrc.setCurrentQuestion(n)

  openCurrent()

proc startIdx0(): bool =
  var s: string
  if not prompt(&"Default start question index [1..4]:", s): return
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

  openUrlInBrowser(browserOpt.get, getQuestionUrl(proj.contestSlug, proj.questionSlug))

  true

proc check(): bool =
  var session = nlccrc.getLeetCodeSession
  if session.len == 0:
    if not sync0(): return
    session = nlccrc.getLeetCodeSession
  if session.len == 0: return

  let lcSession = initJWT(session)
  if lcSession.getExpireTimestamp - getTime().toUnix <= SESSION_EXPIRE_WARNING_SECS:
    echo &"Warning: Session expires at {lcSession.getExpireTime}. Consider refreshing session (logout and login again) in the browser and run \"nlcc sync\" again."

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
  # TODO: custom editor command
  # TODO: custom diff command
  else:
    if not start0(): return -1



when isMainModule:
  quit(main())
