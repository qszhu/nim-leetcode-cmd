import std/[
  sequtils,
  strutils,
]

from checksums/sha1 import nil

import utils



# https://en.wikipedia.org/wiki/HMAC
proc hmacsha1*(key, msg: string): string =
  const blockLen = 64
  const targetLen = 20
  let opad = "\x5c".repeat(blockLen)
  let ipad = "\x36".repeat(blockLen)

  proc hash(msg: string): string =
    cast[string](cast[array[targetLen, uint8]](sha1.secureHash(msg)).toSeq)

  proc getBlockKey(key: string): string =
    result = key
    if result.len > blockLen:
      result = hash(result)
    if result.len < blockLen:
      result &= "\x00".repeat(blockLen - result.len)

  let key = key.getBlockKey
  let okeypad = strxor(key, opad)
  let ikeypad = strxor(key, ipad)
  hash(okeypad & hash(ikeypad & msg))
