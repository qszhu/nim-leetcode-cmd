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
  sequtils,
  strformat,
  strutils,
  times,
]

import ../lib/[args, prompts]
import ../lib/leetcode/lcSession
import ../nlccrcs
import ../consts
import ../projects/projects
import ../utils
import consts
import subcmd/[start, sync, build, test, submit]



const SESSION_EXPIRE_WARNING_SECS = 3 * 24 * 60 * 60

proc showHelp(): int = discard
proc initCurrentProject(): BaseProject
proc openCurrent(): bool

proc sync0(): bool =
  let args = initArgs()
    .addOption(OPT_FORCE, "f")
    .parse

  let force = args.getOption(OPT_FORCE) == "1"

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
    let default = if browserOpt.get == Browser.CHROME: getDefaultChromeProfilePath() else: ""
    if not prompt("Browser profile path", profilePath, default): return

  if not syncCmd(browserOpt.get, profilePath): return

  nlccrc.setBrowser(browserOpt.get)
  nlccrc.setBrowserProfilePath(profilePath)

  true

proc start0(): bool =
  let args = initArgs().parse

  var contestSlug = args.getArg(1).getContestSlug
  if contestSlug.len == 0:
    contestSlug = nlccrc.getCurrentContest

  if not startCmd(contestSlug): return

  nlccrc.setCurrentContest(contestSlug)
  openCurrent()

proc build0(): bool =
  let proj = initCurrentProject()
  buildCmd(proj)

proc test0(): bool =
  let proj = initCurrentProject()
  testCmd(proj)

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

proc initCurrentProject(): BaseProject =
  let contestSlug = nlccrc.getCurrentContest
  let questionSlug = nlccrc.getContestQuestions[nlccrc.getCurrentQuestion]
  let langOpt = nlccrc.getLanguageOpt
  let lang = langOpt.get
  case lang
  of Language.NIM_JS:
    let proj = NimJsProject.new
    proj.initFromProject(contestSlug, questionSlug, lang)
    return proj
  else:
    raise newException(ValueError, "Unsupported language: " & $lang)

proc openCurrent(): bool =
  let proj = initCurrentProject()
  proj.openInEditor

  let browserOpt = nlccrc.getBrowserOpt
  if browserOpt.isNone: return

  openUrlInBrowser(browserOpt.get, getQuestionUrl(proj.contestSlug, proj.questionSlug))

  true

proc check(): bool =
  if nlccrc.getEditorCmd.len == 0:
    nlccrc.setEditorCmd(&"code {TMPL_VAR_SOLUTION_SRC}")

  if nlccrc.getDiffCmd.len == 0:
    nlccrc.setDiffCmd(&"code --diff {TMPL_VAR_DIFF_A} {TMPL_VAR_DIFF_B}")

  var session = nlccrc.getLeetCodeSession
  if session.len == 0:
    if not sync0(): return
    session = nlccrc.getLeetCodeSession
  if session.len == 0: return

  let lcSession = initJWT(session)
  if lcSession.getExpireTimestamp - getTime().toUnix <= SESSION_EXPIRE_WARNING_SECS:
    echo &"Warning: Session expires at {lcSession.getExpireTime}. Consider refresh session in the browser and run \"nlcc sync\" again."

  let langOpt = nlccrc.getLanguageOpt
  if langOpt.isNone:
    var lang: string
    if not prompt("Choose language", lang,
      choices = Language.toSeq.mapIt($it)): return
    try:
      nlccrc.setLanguage(parseEnum[Language](lang))
    except:
      echo "Unknown language: " & lang
      return

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
  else:
    if not start0(): return -1



when isMainModule:
  quit(main())
