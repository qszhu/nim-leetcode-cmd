import lib/rcs



const CFG_FN = ".nlccrc"

const SEC_SYNC = "sync"
const KEY_BROWSER = "browser"
const KEY_PROFILE = "profile"
const KEY_SESSION = "session"
const KEY_LANG = "lang"
const KEY_CONTEST = "contest"
const KEY_EDITOR_CMD = "editor_cmd"


type
  NLCCRC* = RunConfig

proc initNLCCRC*(): NLCCRC {.inline.} =
  initRunConfig(CFG_FN)

proc setBrowser*(self: NLCCRC, v: string) {.inline.} =
  self.set(KEY_BROWSER, v, section = SEC_SYNC)

proc getBrowser*(self: NLCCRC): string {.inline.} =
  self.get(KEY_BROWSER, section = SEC_SYNC)

proc setBrowserProfilePath*(self: NLCCRC, v: string) {.inline.} =
  self.set(KEY_PROFILE, v, section = SEC_SYNC)

proc getBrowserProfilePath*(self: NLCCRC): string {.inline.} =
  self.get(KEY_PROFILE, section = SEC_SYNC)

proc setLeetCodeSession*(self: NLCCRC, v: string) {.inline.} =
  self.set(KEY_SESSION, v)

proc getLeetCodeSession*(self: NLCCRC): string {.inline.} =
  self.get(KEY_SESSION)

proc setLanguage*(self: NLCCRC, v: string) {.inline.} =
  self.set(KEY_LANG, v)

proc getLanguage*(self: NLCCRC): string {.inline.} =
  self.get(KEY_LANG)

proc setCurrentContest*(self: NLCCRC, v: string) {.inline.} =
  self.set(KEY_CONTEST, v)

proc getCurrentContest*(self: NLCCRC): string {.inline.} =
  self.get(KEY_CONTEST)

proc setEditorCmd*(self: NLCCRC, v: string) {.inline.} =
  self.set(KEY_EDITOR_CMD, v)

proc getEditorCmd*(self: NLCCRC): string {.inline.} =
  self.get(KEY_EDITOR_CMD)

let nlccrc* = initNLCCRC()
