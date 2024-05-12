import std/[
  endians,
  os,
  sequtils,
  strformat,
  strutils,
  tempfiles,
]

from checksums/sha1 import nil



proc strxor(a, b: string): string =
  var a = cast[seq[uint8]](a)
  let b = cast[seq[uint8]](b)
  for i in 0 ..< a.len:
    a[i] = a[i] xor b[i]
  cast[string](a)

type
  HmacFunc = proc (key, msg: string): string

# https://en.wikipedia.org/wiki/HMAC
proc hmacsha1(key, msg: string): string =
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

proc writeInt32BE(n: int): string =
  var n = n.int32
  var r: int32
  bigEndian32(addr(r), addr(n))
  let a = cast[array[4, uint8]](r)
  result = cast[string](a.toSeq)

# https://en.wikipedia.org/wiki/PBKDF2
proc pbkdf2*(password, salt: string, iterations, keyLen: int, hmac: HmacFunc = hmacsha1): string =
  var i = 1
  result = ""
  while result.len < keyLen:
    var u = hmac(password, salt & writeInt32BE(i))
    var t = u
    for j in 2 .. iterations:
      u = hmac(password, u)
      t = t.strxor(u)
    result &= t
    i += 1
  result = result[0 ..< keyLen]

proc toHexString(s: string): string =
  s.mapIt(it.ord.toHex(2)).join

proc decrypt*(encrypted, key, iv: string, algo = "aes-128-cbc"): string =
  # TODO: native implementation
  let (_, encFn) = createTempfile("encrypted", ".enc")
  let (_, decFn) = createTempfile("decrypted", ".txt")
  try:
    writeFile(encFn, encrypted)
    let keyHex = key.toHexString
    let ivHex = iv.toHexString
    let cmd = &"openssl enc -{algo} -d -in {encFn} -out {decFn} -K {keyHex} -iv {ivHex}"
    if execShellCmd(cmd) != 0:
      raise newException(CatchableError, "decryption error")
    result = readFile(decFn)
  finally:
    removeFile(encFn)
    removeFile(decFn)

# DON'T USE IN PRODUCTION
# http://www.moserware.com/2009/09/stick-figure-guide-to-advanced.html
