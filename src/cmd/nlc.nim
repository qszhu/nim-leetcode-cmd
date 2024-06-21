# TODO: DRY
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
import subcmd/[build, init, submit, sync, test]



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

  let lcSession = initJWT(nlccrc.getLeetCodeSession)
  echo &"Sync complete. Session now expires at {lcSession.getExpireTime}."
  true

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

proc submit0(): bool =
  let proj = initCurrentProject()
  submitCmd(proj)

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

proc init0(): bool =
  let args = initArgs().parse

  var questionSlug = args.getArg(1).getQuestionSlug

  if not initCmd(questionSlug): return

  nlccrc.setQuestion(questionSlug)
  openCurrent()

proc initCurrentProject(): BaseProject =
  let questionSlug = nlccrc.getQuestion
  let langOpt = nlccrc.getLanguageOpt
  let lang = langOpt.get
  case lang
  of Language.NIM_JS:
    result = NimJsProject.new
  of Language.NIM_WASM:
    result = NimWasmProject.new
  of Language.PYTHON3:
    result = Python3Project.new
  result.initFromProject(questionSlug, lang)

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
  let sessionRemainTime = lcSession.getExpireTimestamp - getTime().toUnix
  if sessionRemainTime <= SESSION_EXPIRE_WARNING_SECS:
    echo &"Warning: session expires at {lcSession.getExpireTime}. Consider refreshing session (logout and login again) in the browser and run \"nlc sync\"."
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
  of CMD_INIT:
    if not init0(): return -1
  of CMD_BUILD:
    if not build0(): return -1
  of CMD_TEST:
    if not build0(): return -1
    if not test0(): return -1
  of CMD_SUBMIT:
    if not build0(): return -1
    if not submit0(): return -1
  of CMD_LANG:
    if not lang0(): return -1
  else:
    return showHelp()



when isMainModule:
  quit(main())
