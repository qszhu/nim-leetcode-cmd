import utils



const TMPL_SOLUTION_CLASS_FN = TMPL_ROOT / "solution_class.tmpl"

const TMPL_VAR_CONSTRUCTOR = "${constructor}"
const TMPL_VAR_METHODS = "${methods}"
const TMPL_VAR_CONSTRUCTOR_CALL = "${constructorCall}"
const TMPL_VAR_METHOD_CALLS = "${methodCalls}"

proc getParam(param: JsonNode): string =
  let name = param["name"].getStr
  let typ = param["type"].getStr.getType
  &"{name}: {typ}"

proc getParams(params: JsonNode): string =
  params.getElems.mapIt(it.getParam).join(", ")

proc genConstructor(metaData: JsonNode): string =
  let classname = metaData["classname"].getStr
  let params = metaData["constructor"]["params"].getParams
  &"""
proc {classname}({params}): Class =
  result.new
  # TODO
"""

proc genMethod(jso: JsonNode): string =
  let name = jso["name"].getStr
  let paramStr = jso["params"].getParams
  let params =
    if paramStr.len == 0: "self: Class"
    else: @["self: Class", paramStr].join(", ")
  let retType = jso["return"]["type"].getStr.getType
  &"""
proc {name}({params}): {retType} =
  discard
  # TODO
"""

proc genMethods(metaData: JsonNode): string =
  metaData["methods"].getElems.mapIt(it.genMethod).join("\n")

proc getReadArgs(params: JsonNode): string =
  var res = newSeq[string]()
  for i, param in params.getElems:
    let readMethod = param["type"].getStr.getReadMethod
    res.add &"params[{i}].{readMethod}"
  res.join(", ")

proc genConstructorCall(metaData: JsonNode): string =
  let classname = metaData["classname"].getStr
  let args = metaData["constructor"]["params"].getReadArgs
  &"""
        of "{classname}":
          c = {classname}({args})
          cWriter.writeRaw "null"
"""

proc genMethodCall(jso: JsonNode): string =
  let name = jso["name"].getStr
  let args = jso["params"].getReadArgs
  let retType = jso["return"]["type"].getStr.getType
  if retType == "void":
    &"""
        of "{name}":
          c.{name}({args})
          cWriter.writeRaw "null"
"""
  else:
    &"""
        of "{name}":
          cWriter.write c.{name}({args})
"""

proc genMethodCalls(metaData: JsonNode): string =
  metaData["methods"].getElems.mapIt(it.genMethodCall).join("\n")

proc genClass*(metaData: JsonNode): string =
  readFile(TMPL_SOLUTION_CLASS_FN)
    .replace(TMPL_VAR_CONSTRUCTOR, genConstructor(metaData))
    .replace(TMPL_VAR_METHODS, genMethods(metaData))
    .replace(TMPL_VAR_CONSTRUCTOR_CALL, genConstructorCall(metaData))
    .replace(TMPL_VAR_METHOD_CALLS, genMethodCalls(metaData))



when isMainModule:
  let metaData = """{"classname":"neighborSum","constructor":{"params":[{"type":"integer[][]","name":"grid"}]},"methods":[{"params":[{"type":"integer","name":"value"}],"name":"adjacentSum","return":{"type":"integer"}},{"params":[{"type":"integer","name":"value"}],"name":"diagonalSum","return":{"type":"integer"}}],"return":{"type":"boolean"},"systemdesign":true}""".parseJson
  block:
    echo genClass(metaData)
