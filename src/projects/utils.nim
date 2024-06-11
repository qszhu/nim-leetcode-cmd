import std/[
  os,
  strformat,
]



proc checkCmd*(cmd: string): bool {.inline.} =
  when defined windows:
    return execShellCmd(&"powershell -c \"Get-Command {cmd}\"") == 0
  else:
    return execShellCmd(&"which {cmd}") == 0
