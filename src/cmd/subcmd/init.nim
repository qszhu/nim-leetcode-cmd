import pkg/nimleetcode

import ../../nlccrcs
import ../../projects/projects
import utils



proc initCmd*(titleSlug: string): bool =
  let client = newLcClient()
  client.setToken(nlccrc.getLeetCodeSession)

  let langOpt = nlccrc.getLanguageOpt

  var res = waitFor client.consolePanelConfig(titleSlug)
  var question = res["data"]["question"]
  let questionId = question["questionId"].getStr
  let testInput = question["exampleTestcases"].getStr
  let metaData = question["metaData"].getStr.parseJson

  res = waitFor client.questionEditorData(titleSlug, login = true)
  question = res["data"]["question"]
  let snippets = initCodeSnippets(question["codeSnippets"])

  res = waitFor client.questionContent(titleSlug)
  let problemDescEn = res["data"]["question"]["content"].getStr

  res = waitFor client.questionTranslations(titleSlug)
  let problemDesc = res["data"]["question"]["translatedContent"].getStr

  let proj = initProject(ProjectInfo(
    titleSlug: titleSlug,
    questionId: questionId,
    lang: langOpt.get,
    testInput: testInput,
    codeSnippets: snippets,
    metaData: metaData,
    problemDesc: problemDesc,
    problemDescEn: problemDescEn
  ))
  proj.initProjectDir

  return true
