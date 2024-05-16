import hmac, utils



type
  HmacFunc = proc (key, msg: string): string

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
