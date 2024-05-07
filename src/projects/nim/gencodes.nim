import std/[
  json,
  re,
  strformat,
  strutils,
]



const TMPL_FUNC_FN = "nimFunc.tmpl"
const TMPL_VAR_FUNCTION_NAME = "{{functionName}}"
const TMPL_VAR_PARAMETERS = "{{parameters}}"
const TMPL_VAR_RETURN_TYPE = "{{returnType}}"

proc getType(ts: string): string =
  case ts
  of "integer", "double", "long": "cfloat"
  of "character", "string": "cstring"
  of "boolean": "bool"
  else:
    if ts =~ re"([^\[]+)\[\]":
      let ts = matches[0]
      &"seq[{getType(ts)}]"
    elif ts =~ re"list<([^>]+)>":
      let ts = matches[0]
      &"seq[{getType(ts)}]"
    else: ts

proc getParams(jso: JsonNode): string =
  var res = newSeq[string]()
  for o in jso:
    let (n, t) = (o["name"].getStr, o["type"].getStr)
    res.add &"{n}: {getType(t)}"
  res.join ", "

proc genFunction(metaData: JsonNode): string =
  let functionName = metaData["name"].getStr
  let parameters = getParams(metaData["params"])
  let returnType = if "return" in metaData: getType(metaData["return"]["type"].getStr) else: "void"
  let tmpl = readFile(TMPL_FUNC_FN)
  result = tmpl.replace(TMPL_VAR_FUNCTION_NAME, functionName)
    .replace(TMPL_VAR_PARAMETERS, parameters)
    .replace(TMPL_VAR_RETURN_TYPE, returnType)

proc genCode*(metaData: JsonNode): string =
  let className = metaData{"classname"}.getStr
  if className.len > 0:
    raise newException(CatchableError, "Class not implemented")
  genFunction(metaData)



when isMainModule:
  doAssert getType("double[]") == "seq[cfloat]"
  doAssert getType("list<character>") == "seq[cstring]"
