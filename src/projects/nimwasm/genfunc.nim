import utils



const TMPL_SOLUTION_FN = TMPL_ROOT / "solution.tmpl"

const TMPL_VAR_ARG_DEFS = "${argDefs}"
const TMPL_VAR_RETURN_VAR_DEF = "${returnVarDef}"
const TMPL_VAR_RETURN_VAR_INIT = "${returnVarInit}"
const TMPL_VAR_READ_ARGS = "${readArgs}"

proc getDefaultVal(t: string): string {.inline.} =
  case t
  of "integer", "long", "double": "0"
  of "string": "\"\""
  of "boolean": "false"
  of "ListNode": "nil"
  else:
    if t.endsWith("[]"): "@[]"
    elif t.startsWith("list<") and t.endsWith(">"): "@[]"
    else:
      raise newException(ValueError, "Default val for type not implemented: " & t)

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
      {name} = reader.{getReadMethod(typ)}
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

proc genFunc*(metaData: JsonNode): string =
  readFile(TMPL_SOLUTION_FN)
    .replace(TMPL_VAR_ARG_DEFS, getArgDefs(metaData))
    .replace(TMPL_VAR_RETURN_VAR_DEF, getReturnVarDef(metaData))
    .replace(TMPL_VAR_RETURN_VAR_INIT, getReturnVarInit(metaData))
    .replace(TMPL_VAR_READ_ARGS, getReadArgs(metaData))



when isMainModule:
  block:
    let metaData = """{"name":"minimumChairs","params":[{"name":"s","type":"string"}],"return":{"type":"integer"}}""".parseJson
    echo genFunc(metaData)
