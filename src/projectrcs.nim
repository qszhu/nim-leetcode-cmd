import std/[
  os,
]

import lib/rcs



const CFG_FN = ".projectrc"

const KEY_CONTEST = "contest"
const KEY_QUESTION = "question"
const KEY_QUESTION_ID = "questionId"
const KEY_CURRENT_SRC = "currentSrc"



type
  ProjectRC* = RunConfig

proc initProjectRC*(dir: string): ProjectRC {.inline.} =
  initRunConfig(dir / CFG_FN)

proc setContestSlug*(self: ProjectRC, v: string) {.inline.} =
  self.set(KEY_CONTEST, v)

proc getContestSlug*(self: ProjectRC): string {.inline.} =
  self.get(KEY_CONTEST)

proc setQuestionSlug*(self: ProjectRC, v: string) {.inline.} =
  self.set(KEY_QUESTION, v)

proc getQuestionSlug*(self: ProjectRC): string {.inline.} =
  self.get(KEY_QUESTION)

proc setQuestionId*(self: ProjectRC, v: string) {.inline.} =
  self.set(KEY_QUESTION_ID, v)

proc getQuestionId*(self: ProjectRC): string {.inline.} =
  self.get(KEY_QUESTION_ID)

proc setCurrentSrc*(self: ProjectRC, v: string) {.inline.} =
  self.set(KEY_CURRENT_SRC, v)

proc getCurrentSrc*(self: ProjectRC): string {.inline.} =
  self.get(KEY_CURRENT_SRC)