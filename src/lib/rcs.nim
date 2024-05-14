import std/[
  os,
  parsecfg,
]



type
  RunConfig* = ref object
    fn: string
    cfg: Config

proc save(self: RunConfig) =
  self.cfg.writeConfig(self.fn)

proc initRunConfig*(fn: string): RunConfig =
  result.new
  result.fn = fn
  if not fileExists(fn):
    result.cfg = newConfig()
    result.save()
  else:
    result.cfg = loadConfig(result.fn)

proc set*(self: RunConfig, key, value: string, section = "") =
  self.cfg.setSectionKey(section, key, value)
  self.save

proc get*(self: RunConfig, key: string, section = "", default = ""): string =
  self.cfg.getSectionValue(section, key, default)
