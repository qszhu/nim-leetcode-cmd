import std/[
  parseopt,
  sequtils,
  tables,
]



type
  ArgDef = ref object
    short2Long: Table[string, string]

  Argument = ref object
    args: seq[string]
    options: Table[string, string]

proc initArgs*(): ArgDef =
  result.new
  result.short2Long = initTable[string, string]()

proc addOption*(self: ArgDef, long, short: string): ArgDef =
  self.short2Long[short] = long
  return self

proc hasShort(self: ArgDef, short: string): bool {.inline.} =
  short in self.short2Long

proc hasLong(self: ArgDef, long: string): bool {.inline.} =
  long in self.short2Long.values.toSeq

proc getLong(self: ArgDef, short: string): string {.inline.} =
  self.short2Long[short]

proc parse*(self: ArgDef): Argument =
  result.new
  result.args = newSeq[string]()
  result.options = initTable[string, string]()

  for kind, key, val in getopt():
    case kind
    of cmdArgument:
      result.args.add key
    of cmdLongOption:
      if not self.hasLong(key): continue
      result.options[key] = val
    of cmdShortOption:
      if not self.hasShort(key): continue
      result.options[self.getLong(key)] = val
    else: discard

proc getArg*(self: Argument, idx: int, default = ""): string {.inline.} =
  if idx in 0 ..< self.args.len: self.args[idx] else: default

proc getOption*(self: Argument, key: string, default = ""): string {.inline.} =
  self.options.getOrDefault(key, default)
