import std/[
  options,
  strformat,
  strutils,
]

import pkg/nimleetcode

import lib/rcs
import consts

export options, consts



const CFG_FN = ".nlccrc"

const SEC_SYNC = "sync"
const KEY_BROWSER = "browser"
const KEY_PROFILE = "profile"
const KEY_SESSION = "session"
const KEY_LANG = "lang"
const KEY_CONTEST = "contest"
const KEY_EDITOR_CMD = "editor_cmd"
const KEY_DIFF_CMD = "diff_cmd"
const KEY_QUESTIONS = "questions"
const KEY_QUESTION_TITLES = "question_titles"
const KEY_CURRENT_QUESTION = "current_question"
const KEY_START_INDEX = "start_index"

const DEFAULT_EDITOR_CMD = &"code -g {TMPL_VAR_SOLUTION_SRC}:1024"
const DEFAULT_DIFF_CMD = &"code --diff {TMPL_VAR_DIFF_A} {TMPL_VAR_DIFF_B}"
const DEFAULT_START_IDX = 0

const KEY_QUESTION = "question"


type
  NLCCRC* = RunConfig

proc initNLCCRC*(): NLCCRC {.inline.} =
  initRunConfig(CFG_FN)

proc setBrowser*(self: NLCCRC, v: Browser) {.inline.} =
  self.set(KEY_BROWSER, $v, section = SEC_SYNC)

proc getBrowserOpt*(self: NLCCRC): Option[Browser] {.inline.} =
  try:
    some(parseEnum[Browser](self.get(KEY_BROWSER, section = SEC_SYNC)))
  except:
    none(Browser)

proc setBrowserProfilePath*(self: NLCCRC, v: string) {.inline.} =
  self.set(KEY_PROFILE, v, section = SEC_SYNC)

proc getBrowserProfilePath*(self: NLCCRC): string {.inline.} =
  self.get(KEY_PROFILE, section = SEC_SYNC)

proc setLeetCodeSession*(self: NLCCRC, v: string) {.inline.} =
  self.set(KEY_SESSION, v)

proc getLeetCodeSession*(self: NLCCRC): string {.inline.} =
  self.get(KEY_SESSION)

proc setLanguage*(self: NLCCRC, v: Language) {.inline.} =
  self.set(KEY_LANG, $v)

proc getLanguageOpt*(self: NLCCRC): Option[Language] {.inline.} =
  try:
    some(parseEnum[Language](self.get(KEY_LANG)))
  except:
    none(Language)

proc setCurrentContest*(self: NLCCRC, v: string) {.inline.} =
  self.set(KEY_CONTEST, v)

proc getCurrentContest*(self: NLCCRC): string {.inline.} =
  self.get(KEY_CONTEST)

proc setEditorCmd*(self: NLCCRC, v: string) {.inline.} =
  self.set(KEY_EDITOR_CMD, v)

proc getEditorCmd*(self: NLCCRC, default = DEFAULT_EDITOR_CMD): string {.inline.} =
  self.get(KEY_EDITOR_CMD, default = default)

proc setDiffCmd*(self: NLCCRC, v: string) {.inline.} =
  self.set(KEY_DIFF_CMD, v)

proc getDiffCmd*(self: NLCCRC, default = DEFAULT_DIFF_CMD): string {.inline.} =
  self.get(KEY_DIFF_CMD, default = default)

proc setContestQuestions*(self: NLCCRC, slugs: seq[string]) {.inline.} =
  self.set(KEY_QUESTIONS, slugs.join(","))

proc getContestQuestions*(self: NLCCRC): seq[string] {.inline.} =
  self.get(KEY_QUESTIONS).split(",")

proc setContestQuestionTitles*(self: NLCCRC, titles: seq[string]) {.inline.} =
  self.set(KEY_QUESTION_TITLES, titles.join(","))

proc getContestQuestionTitles*(self: NLCCRC): seq[string] {.inline.} =
  self.get(KEY_QUESTION_TITLES).split(",")

proc setCurrentQuestion*(self: NLCCRC, i: int) {.inline.} =
  self.set(KEY_CURRENT_QUESTION, $i)

proc getCurrentQuestion*(self: NLCCRC): int {.inline.} =
  self.get(KEY_CURRENT_QUESTION).parseInt

proc setQuestion*(self: NLCCRC, slug: string) {.inline.} =
  self.set(KEY_QUESTION, slug)

proc getQuestion*(self: NLCCRC): string {.inline.} =
  self.get(KEY_QUESTION)

proc setStartIndex*(self: NLCCRC, i: int) {.inline.} =
  self.set(KEY_START_INDEX, $i)

proc getStartIndex*(self: NLCCRC, default = DEFAULT_START_IDX): int {.inline.} =
  self.get(KEY_START_INDEX, default = $default).parseInt

let nlccrc* = initNLCCRC()
