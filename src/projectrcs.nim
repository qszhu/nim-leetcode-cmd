import std/[
  json,
  os,
]

import lib/rcs



const CFG_FN = ".projectrc"

const KEY_QUESTION_ID = "questionId"
const KEY_CURRENT_SRC = "currentSrc"
const KEY_META_DATA = "metaData"



type
  ProjectRC* = RunConfig

proc initProjectRC*(dir: string): ProjectRC {.inline.} =
  initRunConfig(dir / CFG_FN)

proc setQuestionId*(self: ProjectRC, v: string) {.inline.} =
  self.set(KEY_QUESTION_ID, v)

proc getQuestionId*(self: ProjectRC): string {.inline.} =
  self.get(KEY_QUESTION_ID)

proc setCurrentSrc*(self: ProjectRC, v: string) {.inline.} =
  self.set(KEY_CURRENT_SRC, v)

proc getCurrentSrc*(self: ProjectRC): string {.inline.} =
  self.get(KEY_CURRENT_SRC)

proc setMetaData*(self: ProjectRC, m: JsonNode) {.inline.} =
  self.set(KEY_META_DATA, $m)

proc getMetaData*(self: ProjectRC): JsonNode {.inline.} =
  self.get(KEY_META_DATA).parseJson
