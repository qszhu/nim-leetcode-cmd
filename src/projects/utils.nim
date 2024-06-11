import std/[
  os,
  strformat,
]



proc checkCmd*(cmd: string): bool {.inline.} =
  execShellCmd(&"which {cmd}") == 0
