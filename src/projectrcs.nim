import std/[
  os,
  strutils,
]

import lib/rcs



const CFG_FN = ".projectrc"

const KEY_QUESTION_ID = "questionId"
const KEY_QUESTION_ORDER = "questionOrder"
const KEY_CURRENT_SRC = "currentSrc"



type
  ProjectRC* = RunConfig

proc initProjectRC*(dir: string): ProjectRC {.inline.} =
  initRunConfig(dir / CFG_FN)

proc setQuestionId*(self: ProjectRC, v: string) {.inline.} =
  self.set(KEY_QUESTION_ID, v)

proc getQuestionId*(self: ProjectRC): string {.inline.} =
  self.get(KEY_QUESTION_ID)

proc setQuestionOrder*(self: ProjectRC, i: int) {.inline.} =
  self.set(KEY_QUESTION_ORDER, $i)

proc getQuestionOrder*(self: ProjectRC): int {.inline.} =
  self.get(KEY_QUESTION_ORDER).parseInt

proc setCurrentSrc*(self: ProjectRC, v: string) {.inline.} =
  self.set(KEY_CURRENT_SRC, v)

proc getCurrentSrc*(self: ProjectRC): string {.inline.} =
  self.get(KEY_CURRENT_SRC)