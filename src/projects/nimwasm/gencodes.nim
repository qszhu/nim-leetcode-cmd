import genfunc, genclass, utils



proc genCode*(metaData: JsonNode): string =
  if "classname" in metaData:
    genClass(metaData)
  else:
    genFunc(metaData)
