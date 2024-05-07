import std/[
  base64,
  endians,
  os,
  osproc,
  sequtils,
  strformat,
  strutils,
  tempfiles,
]



proc writeInt32BE(n: int): string =
  var n = n.int32
  var r: int32
  bigEndian32(addr(r), addr(n))
  let a = cast[array[4, uint8]](r)
  result = cast[string](a.toSeq)

proc strxor(a, b: string): string =
  var a = cast[seq[uint8]](a)
  let b = cast[seq[uint8]](b)
  for i in 0 ..< a.len:
    a[i] = a[i] xor b[i]
  cast[string](a)

proc hmac(key, msg: string, algo = "sha1"): string =
  # TODO: native implementation
  let (_, inputFn) = createTempfile("message", ".bin")
  try:
    writeFile(inputFn, msg)
    let cmd = &"openssl dgst -{algo} -hmac {key} --binary {inputFn} | openssl base64"
    result = execProcess(cmd).decode
  finally:
    removeFile(inputFn)

# https://en.wikipedia.org/wiki/PBKDF2
proc pbkdf2*(password, salt: string, iterations, keyLen: int): string =
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
