import std/[
  endians,
  sequtils,
  strutils,
]



proc strxor*(a, b: string): string =
  var a = cast[seq[uint8]](a)
  let b = cast[seq[uint8]](b)
  for i in 0 ..< a.len:
    a[i] = a[i] xor b[i]
  cast[string](a)

proc writeInt32BE*(n: int): string =
  var n = n.int32
  var r: int32
  bigEndian32(addr(r), addr(n))
  let a = cast[array[4, uint8]](r)
  result = cast[string](a.toSeq)

proc toHexString*(s: string): string =
  s.mapIt(it.ord.toHex(2)).join

proc toUint32BE*(bytes: var seq[uint8], offset = 0): uint32 {.inline.} =
  (
    (bytes[offset + 0].uint32 shl 24) or
    (bytes[offset + 1].uint32 shl 16) or
    (bytes[offset + 2].uint32 shl 8) or
    (bytes[offset + 3].uint32 shl 0)
  )

proc fromUint32BE*(bytes: var seq[uint8], w: uint32, o = 0) =
  bytes[o + 0] = (w shr 24).uint8
  bytes[o + 1] = (w shr 16 and 0xff).uint8
  bytes[o + 2] = (w shr 8 and 0xff).uint8
  bytes[o + 3] = (w and 0xff).uint8

proc fromUint32BE*(w: uint32): seq[uint8] =
  result = newSeq[uint8](4)
  result.fromUint32BE(w)
