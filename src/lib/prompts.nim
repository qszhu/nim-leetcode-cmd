import std/[
  rdstdin,
  strformat,
]



proc prompt*(msg: string, resp: var string, default = ""): bool =
  let msg = if default.len > 0: &"{msg} [{default}]: " else: &"{msg}: "
  result = readLineFromStdin(msg, resp)
  if result and resp.len == 0 and default.len > 0:
    resp = default
