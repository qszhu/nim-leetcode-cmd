import std/[
  json,
  os,
  strformat,
  strutils,
]



const TMPL_ROOT = "tmpl" / "nimjs"
const TMPL_FUNC_FN = TMPL_ROOT / "nimjsFunc.tmpl"

const TMPL_VAR_FUNCTION_NAME = "{{functionName}}"
const TMPL_VAR_PARAMETERS = "{{parameters}}"
const TMPL_VAR_RETURN_TYPE = "{{returnType}}"

proc getType(ts: string): string =
  case ts
  of "integer", "double", "long": "JsNum"
  of "character", "string": "JsStr"
  of "boolean": "JsBool"
  else:
    if ts.endsWith("[]"):
      &"seq[{getType(ts[0 ..< ^2])}]"
    elif ts.startsWith("list<") and ts.endsWith(">"):
      let ts = ts[5 ..< ^1]
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
  result = tmpl
    .replace(TMPL_VAR_FUNCTION_NAME, functionName)
    .replace(TMPL_VAR_PARAMETERS, parameters)
    .replace(TMPL_VAR_RETURN_TYPE, returnType)

proc genCode*(metaData: JsonNode): string =
  let className = metaData{"classname"}.getStr
  if className.len > 0:
    # TODO: generate class
    raise newException(CatchableError, "Class not implemented")
  genFunction(metaData)



when isMainModule:
  doAssert getType("double[]") == "seq[JsNum]"
  doAssert getType("integer[][]") == "seq[seq[JsNum]]"
  doAssert getType("list<character>") == "seq[JsStr]"
  doAssert getType("list<integer>") == "seq[JsNum]"
  doAssert getType("list<list<integer>>") == "seq[seq[JsNum]]"
