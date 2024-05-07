import std/[
  base64,
  json,
  strutils,
]

export json



type
  JsonWebToken* = object
    raw: string
    header, payload*: JsonNode
    signature: string

proc initJWT*(jwt: string): JsonWebToken =
  let parts = jwt.split(".")
  doAssert parts.len == 3

  let header = parts[0].decode.parseJson
  doAssert header["typ"].getStr == "JWT"

  let payload = parts[1].decode.parseJson
  let signature = parts[2]
  JsonWebToken(raw: jwt, header: header, payload: payload, signature: signature)

proc `$`*(self: JsonWebToken): string {.inline.} =
  self.raw
