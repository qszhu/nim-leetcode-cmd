import  std/[
  json,
  os,
  sequtils,
  strformat,
  strutils,
]

export json, os, sequtils, strformat, strutils



const TMPL_ROOT* = "tmpl" / "nimwasm"

proc getType*(t: string): string {.inline.} =
  case t
  of "integer": "int"
  of "long": "int64"
  of "double": "float"
  of "character", "string": "string"
  of "boolean": "bool"
  of "ListNode": "ListNode"
  else:
    if t.endsWith("[]"): "seq[" & t[0 ..< ^2].getType & "]"
    elif t.startsWith("list<") and t.endsWith(">"):
      "seq[" & t[5 ..< ^1].getType & "]"
    else:
      raise newException(ValueError, "Type not implemented: " & t)

proc getReadMethod*(t: string): string {.inline.} =
  case t
  of "integer": "readInt"
  of "long": "readLong"
  of "double": "readDouble"
  of "character", "string": "readString"
  of "boolean": "readBool"
  of "ListNode": "readListNode"
  else:
    if t.endsWith("[][]"): t[0 ..< ^4].getReadMethod & "s2D"
    elif t.endsWith("[]"): t[0 ..< ^2].getReadMethod & "s"
    elif t.startsWith("list<list<") and t.endsWith(">>"):
      t[10 ..< ^2].getReadMethod & "s2D"
    elif t.startsWith("list<") and t.endsWith(">"):
      t[5 ..< ^1].getReadMethod & "s"
    else:
      raise newException(ValueError, "Read method for type not implemented: " & t)
