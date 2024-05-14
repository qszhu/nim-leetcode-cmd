import std/[
  json,
  pegs,
  sequtils,
  strutils,
]

from unicode import nil

import ../parsec



const TAG_VAR_STMT = "varStmt"
const TAG_IDENT = "ident"
const TAG_STRING = "str"
const TAG_BOOL = "bool"
const TAG_OBJECT = "obj"
const TAG_KEY_VAL = "keyVal"
const TAG_ARRAY = "array"
const TAG_PARSE_JSON = "parseJson"
const TAG_OR = "or"

proc WS(): Parser {.inline.} =
  pegExp(r"\s*")

proc token(s: string, tag = s): Parser {.inline.} =
  seqOf(WS(), str(s, tag)).map(res => res.children[1])

proc pegToken(pat: string, tag: string): Parser {.inline.} =
  seqOf(WS(), pegExp(pat, tag)).map(res => res.children[1])

proc EQ(): Parser {.inline.} = token("=")
proc LBRACE(): Parser {.inline.} = token("{")
proc RBRACE(): Parser {.inline.} = token("}")
proc COMMA(): Parser {.inline.} = token(",")
proc COLON(): Parser {.inline.} = token(":")
proc SQUOTE(): Parser {.inline.} = token("'")
proc SEMICOLON(): Parser {.inline.} = token(";")
proc LBRACKET(): Parser {.inline.} = token("[")
proc RBRACKET(): Parser {.inline.} = token("]")
proc COND_OR(): Parser {.inline.} = token("||")
# proc LPAREN(): Parser {.inline.} = token("(")
proc RPAREN(): Parser {.inline.} = token(")")

proc VAR(): Parser {.inline.} = token("var")
proc TRUE(): Parser {.inline.} = token("true", tag = TAG_BOOL)
proc FALSE(): Parser {.inline.} = token("false", tag = TAG_BOOL)

proc Ident(): Parser {.inline.} = pegToken(r"\ident", tag = TAG_IDENT)

proc Obj(): Parser
proc KeyVals(): Parser
proc KeyVal(): Parser
proc Val(): Parser
proc Bool(): Parser
proc Str(): Parser
proc Expr(): Parser
proc BinaryExpr(): Parser
proc Term(): Parser
proc Arr(): Parser
proc Stmt(): Parser
proc JsonParseStmt(): Parser

# VarStmt <- var Ident = Obj ;
proc VarStmt(): Parser =
  lazy(() =>
    seqOf(VAR(), Ident(), EQ(), Obj(), zeroOrOne(SEMICOLON())))
    .map(res =>
      newParsed(@[res.children[1], res.children[3]], tag = TAG_VAR_STMT))

# Obj <- { KeyVals }
proc Obj(): Parser =
  lazy(() =>
    between(LBRACE(), RBRACE())(KeyVals()))
    .map proc (res: Parsed): Parsed =
      result = res
      result.tag = TAG_OBJECT

# KeyVals <- KeyVal (, KeyVal)*
proc KeyVals(): Parser =
  lazy(() =>
    seqOf(sepBy(COMMA())(KeyVal()), zeroOrOne(COMMA())))
    .map(res =>
      res.children[0])

# KeyVal <- Ident : Val
proc KeyVal(): Parser =
  lazy(() =>
    seqOf(oneOf(Ident(), Str()), COLON(), Val()))
    .map(res =>
      newParsed(@[res.children[0], res.children[2]], tag = TAG_KEY_VAL))

# Val <- Bool | Str | Obj | Arr | Stmt
proc Val(): Parser =
  lazy(() =>
    oneOf(Bool(), Str(), Obj(), Arr(), Stmt()))

# Val <- true | false
proc Bool(): Parser =
  lazy(() =>
    oneOf(TRUE(), FALSE()))

proc unescapeUnicode(s: string): string
proc Str(): Parser =
  lazy(() =>
    between(SQUOTE(), SQUOTE())(pegExp(r"(!\' .)*", tag = TAG_STRING)))
    .map(res =>
      (res.val = unescapeUnicode(res.val); res))

proc Arr(): Parser =
  lazy(() =>
    between(LBRACKET(), RBRACKET())(
      seqOf(sepBy(COMMA())(Val()), zeroOrOne(COMMA()))))
      .map(proc (res: Parsed): Parsed =
        result = res.children[0]
        result.tag = TAG_ARRAY
      )

proc Expr(): Parser =
  lazy(() =>
    oneOf(BinaryExpr(), Term()))

proc BinaryExpr(): Parser =
  lazy(() =>
    seqOf(Term(), COND_OR(), Term()))
    .map(res =>
      newParsed(@[res.children[0], res.children[2]], tag = TAG_OR))

proc Term(): Parser =
  lazy(() =>
    oneOf(Str()))

proc Stmt(): Parser =
  lazy(() =>
    oneOf(JsonParseStmt()))

proc JsonParseStmt(): Parser =
  lazy(() =>
    between(token("JSON.parse("), RPAREN())(Expr()))
    .map(res =>
      newParsed(@[res], tag = TAG_PARSE_JSON))

proc codePointsToString(hex: string): string {.inline.} =
  unicode.toUTF8(unicode.Rune(fromHex[uint32](hex)))

proc unescapeUnicode(s: string): string =
  var i = 0
  while i < s.len:
    if s[i] == '\\':
      if i + 1 < s.len:
        if s[i + 1] == 'u':
          if i + 2 < s.len:
            if s[i + 2] == '{': # \u{...}
              var j = i + 3
              while j < s.len and s[j] != '}': j += 1
              result &= s[i + 3 ..< j].codePointsToString
              i = j + 1
            elif i + 5 < s.len: # \uHHHH
              result &= s[i + 2 .. i + 5].codePointsToString
              i += 6
        elif s[i + 1] == 'x' and i + 3 < s.len: # \xHH
          result &= s[i + 2 .. i + 3].codePointsToString
          i += 4
    else:
      result &= s[i]
      i += 1

proc getPageData(s: string): string =
  var pageData = newSeq[string]()
  for line in s.split("\n"):
    if line =~ peg"\s+ 'var' \s+ 'pageData' \s+ '=' \s+ '{' \s*":
      pageData.add line
    elif pageData.len > 0:
      if line =~ peg"\s* '</script>' \s*":
        break
      pageData.add line
  pageData.join "\n"

proc toJson(p: Parsed): JsonNode =
  case p.kind
  of ParsedKind.Leaf:
    case p.tag
    of TAG_STRING:
      return %(p.val)
    of TAG_BOOL:
      return %(p.val == "true")
    else:
      raise newException(ValueError, "Unknown leaf tag: " & p.tag)
  of ParsedKind.Node:
    case p.tag
    of TAG_OBJECT:
      result = %*{}
      for kv in p.children:
        let parsedKey = kv.children[0]
        let parsedVal = kv.children[1]
        case parsedKey.tag
        of TAG_IDENT, TAG_STRING:
          result[parsedKey.val] = parsedVal.toJson
        else:
          raise newException(CatchableError, "Unknown key tag: " & parsedKey.tag)
    of TAG_PARSE_JSON:
      case p.children[0].tag
      of TAG_STRING:
        return p.children[0].val.parseJson
      of TAG_OR:
        return p.children[0].children[0].val.parseJson
      else:
        raise newException(CatchableError, "Unknown parseJson tag: " & p.children[0].tag)
    of TAG_ARRAY:
      return %(p.children.mapIt(it.toJson))
    else:
      raise newException(CatchableError, "Unknown node tag: " & p.tag)

proc parsePageData*(htmlSrc: string): JsonNode =
  let src = getPageData(htmlSrc).strip
  let p = VarStmt()
  let res = p.parseToEnd(src)
  if res.kind != ResultKind.Ok:
    raise newException(ValueError, "Parse page data error: " & res.msg)
  let parsed = res.val.result
  return toJson(parsed.children[1])

when isMainModule:
  echo parsePageData(readFile("out.html"))
