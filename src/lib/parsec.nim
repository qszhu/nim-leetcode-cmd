import std/[
  pegs,
  sequtils,
  strformat,
  sugar,
]

export sugar



type
  ResultKind* = enum
    Error, Ok

  Result*[T] = ref object
    case kind*: ResultKind
    of Error:
      msg*: string
    of Ok:
      val*: T

proc `$`*(res: Result): string {.inline.} =
  case res.kind
  of Error: "Error: " & res.msg
  of Ok: $res.val



type
  ParsedKind* = enum
    Leaf, Node

  Parsed* {.acyclic.} = ref object
    tag*: string
    case kind*: ParsedKind
    of Leaf:
      val*: string
      pos*: int
    of Node:
      children*: seq[Parsed]

proc `$`*(r: Parsed): string {.inline.} =
  case r.kind:
  of Leaf: &"[tag: {r.tag}, val: \"{r.val}\", pos: {r.pos}]"
  of Node: &"[tag: {r.tag}, children: {r.children}]"

proc pprint*(r: Parsed, ident = "") =
  if r == nil: return
  case r.kind:
  of Leaf:
    echo ident, r
  of Node:
    echo ident, "[tag: " & r.tag & ", children:"
    for c in r.children:
      pprint(c, ident & "  ")
    echo ident, "]"

proc newParsedLeaf(pos: int, val: string, tag: string = ""): Parsed =
  Parsed(kind: Leaf, val: val, pos: pos, tag: tag)

proc newParsed*(children: seq[Parsed] = @[], tag: string = ""): Parsed =
  Parsed(kind: Node, children: children, tag: tag)



type
  ParserState* = ref object
    target*: string
    idx*: int
    result*: Parsed

proc `$`*(s: ParserState): string {.inline.} =
  &"[target: \"{s.target}\", index: {s.idx}, result: {s.result}]"

proc newParserState(target: string, idx: int = 0, res: Parsed = nil): ParserState =
  ParserState(target: target, idx: idx, result: res)

proc peek(self: ParserState, l: int = 10): string {.inline.} =
  self.target[self.idx ..< min(self.idx + l, self.target.len)]



type
  ParserResult = Result[ParserState]

proc newParseOk(state: ParserState): ParserResult {.inline.} =
  ParserResult(kind: Ok, val: state)

proc newParseError(msg: string): ParserResult {.inline.} =
  ParserResult(kind: Error, msg: msg)



type
  ParserFn = proc (state: ParserState): ParserResult

  Parser* = ref object
    parserFn: ParserFn

proc newParser(parserFn: ParserFn): Parser {.inline.} =
  Parser(parserFn: parserFn)

proc parse*(self: Parser, target: string): ParserResult =
  self.parserFn newParserState(target)

proc parseToEnd*(self: Parser, target: string): ParserResult =
  let res = self.parse target
  if res.kind == Ok and res.val.idx != target.len:
    newParseError &"Parsing end at {res.val.idx}: {res.val.peek}"
  else: res

proc map*(self: Parser, fn: proc (res: Parsed): Parsed): Parser =
  newParser proc (state: ParserState): ParserResult =
    result = self.parserFn state
    if result.kind == Ok:
      result.val.result = fn(result.val.result)

proc lazy*(thunk: proc (): Parser): Parser =
  newParser proc (state: ParserState): ParserResult =
    thunk().parserFn state



proc str*(s: string, tag = ""): Parser =
  newParser proc (state: ParserState): ParserResult =
    let (target, idx) = (state.target, state.idx)
    if idx + s.len <= target.len and target[idx ..< idx + s.len] == s:
      newParseOk newParserState(target, idx + s.len, newParsedLeaf(idx, s, tag))
    else:
      newParseError &"str: Tried to match \"{s}\", but got \"{state.peek(s.len)}\". (\"{state.peek}\")"

proc pegExp*(pattern: string, tag = ""): Parser =
  newParser proc (state: ParserState): ParserResult =
    let (target, idx) = (state.target, state.idx)
    if target[idx .. ^1] =~ (&"{{^{pattern}}}").peg:
      let res = matches[0]
      newParseOk newParserState(target, idx + res.len, newParsedLeaf(idx, res, tag))
    else:
      newParseError &"pegExp: Tried to match \"{pattern}\", but got \"{state.peek}\"."



proc oneOf*(parsers: varargs[Parser]): Parser =
  let parsers = parsers.toSeq
  newParser proc (state: ParserState): ParserResult =
    for parser in parsers:
      let res = parser.parserFn state
      case res.kind:
      of Error: continue
      of Ok: return res
    newParseError &"oneOf: Unable to match any parser at index {state.idx}: \"{state.peek}\"."

proc seqOf*(parsers: varargs[Parser]): Parser =
  let parsers = parsers.toSeq
  newParser proc (state: ParserState): ParserResult =
    var
      results = newParsed()
      nextState = state
    for parser in parsers:
      let res = parser.parserFn nextState
      case res.kind:
      of Error: return res
      of Ok:
        nextState = res.val
        results.children.add nextState.result
    newParseOk newParserState(nextState.target, nextState.idx, results)

proc zeroOrMore*(parser: Parser): Parser =
  newParser proc (state: ParserState): ParserResult =
    var
      results = newParsed()
      nextState = state
    while true:
      let res = parser.parserFn nextState
      case res.kind:
      of Error: break
      of Ok:
        nextState = res.val
        results.children.add nextState.result
    if results.children.len == 0: results = nil
    newParseOk newParserState(nextState.target, nextState.idx, results)

proc oneOrMore*(parser: Parser): Parser =
  newParser proc (state: ParserState): ParserResult =
    var
      results = newParsed()
      nextState = state
    while true:
      let res = parser.parserFn nextState
      case res.kind:
      of Error: break
      of Ok:
        nextState = res.val
        results.children.add nextState.result
    if results.children.len > 0:
      newParseOk newParserState(nextState.target, nextState.idx, results)
    else:
      newParseError &"oneOrMore: Unable to match parser at index {state.idx}: \"{state.peek}\"."

proc zeroOrOne*(parser: Parser): Parser =
  newParser proc (state: ParserState): ParserResult =
    let res = parser.parserFn(state)
    case res.kind:
    of Error: newParseOk newParserState(state.target, state.idx)
    of Ok: res

proc between*(left, right: Parser): proc (content: Parser): Parser =
  return proc (content: Parser): Parser =
    seqOf(left, content, right)
      .map res => res.children[1]

proc sepBy*(sep: Parser): proc (value: Parser): Parser =
  return proc (value: Parser): Parser =
    zeroOrOne(seqOf(value, zeroOrMore(seqOf(sep, value))))
      .map proc (res: Parsed): Parsed =
        if res == nil: return nil
        result = newParsed(tag = "list")
        let (head, rest) = (res.children[0], res.children[1])
        result.children.add head
        if rest != nil:
          for r in rest.children:
            result.children.add r.children[1]
