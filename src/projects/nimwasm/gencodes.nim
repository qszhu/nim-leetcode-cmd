import std/[
  json,
  os,
  strformat,
  strutils,
]



const TMPL_ROOT = "tmpl" / "nimwasm"
const TMPL_SOLUTION_FN = TMPL_ROOT / "solution.tmpl"

const TMPL_VAR_ARG_DEFS = "${argDefs}"
const TMPL_VAR_RETURN_VAR_DEF = "${returnVarDef}"
const TMPL_VAR_RETURN_VAR_INIT = "${returnVarInit}"
const TMPL_VAR_READ_ARGS = "${readArgs}"

proc getType(t: string): string {.inline.} =
  case t
  of "integer": "int"
  of "long": "int64"
  of "double": "float"
  of "string": "string"
  of "boolean": "bool"
  of "integer[]": "seq[int]"
  of "integer[][]": "seq[seq[int]]"
  else:
    raise newException(ValueError, "Type not implemented: " & t)

proc getDefaultVal(t: string): string {.inline.} =
  case t
  of "integer", "long", "double": "0"
  of "string": "\"\""
  of "boolean": "false"
  of "integer[]": "newSeq[int]()"
  of "integer[][]": "newSeq[seq[int]]()"
  else:
    raise newException(ValueError, "Type not implemented: " & t)

proc getReadMethod(t: string): string {.inline.} =
  case t
  of "integer": "readInt[int](reader)"
  of "long": "readInt[int64](reader)"
  of "double": "reader.readDouble"
  of "string": "reader.readString"
  of "boolean": "reader.readBool"
  of "integer[]": "readInts[int](reader)"
  of "integer[][]": "readInts2D[int](reader)"
  else:
    raise newException(ValueError, "Type not implemented: " & t)

proc getArgDefs(metaData: JsonNode): string =
  var res = newSeq[string]()
  for param in metaData["params"]:
    let name = param["name"].getStr
    let typ = param["type"].getStr
    res.add (&"""
var {name}: {getType(typ)}
""").strip
  res.join("\n")

proc getReadArgs(metaData: JsonNode): string =
  var res = newSeq[string]()
  for param in metaData["params"]:
    let name = param["name"].getStr
    let typ = param["type"].getStr
    res.add (&"""
    {name} = {getReadMethod(typ)}
""").strip(leading = false)

  res.join("\n")

proc getReturnVarDef(metaData: JsonNode): string =
  let returnVarType = getType(metaData["return"]["type"].getStr)
  (&"""
var res: {returnVarType}
""").strip(leading = false)

proc getReturnVarInit(metaData: JsonNode): string =
  let defaultVal = getDefaultVal(metaData["return"]["type"].getStr)
  (&"""
  res = {defaultVal}
""").strip(leading = false)

proc genCode*(metaData: JsonNode): string =
  readFile(TMPL_SOLUTION_FN)
    .replace(TMPL_VAR_ARG_DEFS, getArgDefs(metaData))
    .replace(TMPL_VAR_RETURN_VAR_DEF, getReturnVarDef(metaData))
    .replace(TMPL_VAR_RETURN_VAR_INIT, getReturnVarInit(metaData))
    .replace(TMPL_VAR_READ_ARGS, getReadArgs(metaData))

when isMainModule:
  let metaData = """{"name":"minimumChairs","params":[{"name":"s","type":"string"}],"return":{"type":"integer"}}""".parseJson
  echo genCode(metaData)
