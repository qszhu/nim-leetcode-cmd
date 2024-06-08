const ROOT_DIR* = "contests"

const TMPL_VAR_SOLUTION_SRC* = "{{solutionSrc}}"
const TMPL_VAR_DIFF_A* = "{{diffA}}"
const TMPL_VAR_DIFF_B* = "{{diffB}}"

type Language* = enum
  NIM_JS = "nimjs"
  PYTHON3 = "python3"
  # JAVA = "java"
  # JAVASCRIPT = "javascript"
  # TYPESCRIPT = "typescript"
  # CPP = "cpp"

type SubmitLanguage* = enum
  JAVASCRIPT = "javascript"
  PYTHON3 = "python3"
