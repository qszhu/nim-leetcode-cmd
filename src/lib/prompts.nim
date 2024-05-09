import std/[
  rdstdin,
  strformat,
  strutils,
]



proc prompt*(msg: string, resp: var string, default = "", choices: seq[string] = @[]): bool =
  var msgs = @[msg]
  if choices.len > 0:
    msgs.add "[" & choices.join("|") & "]"
  if default.len > 0:
    msgs.add &"({default})"
  let msg = msgs.join(" ") & ": "
  result = readLineFromStdin(msg, resp)
  if result and resp.len == 0 and default.len > 0:
    resp = default
