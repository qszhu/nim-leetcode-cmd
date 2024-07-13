import pkg/nimleetcode

import ../../projects/projects
import ../../nlccrcs
import utils
import ../consts



proc submitCmd*(proj: BaseProject): bool =
  let client = newLcClient()
  client.setToken(nlccrc.getLeetCodeSession)

  let res = proj.submit(client)
  showStdOutput(res)

  # Runtime Error
  if showRuntimeError(res): return

  let status = showStatus(res)
  showPassedCases(res)

  # Wrong Answer, etc.
  if status != STATUS_ACCEPTED:
    let lastTestCase = res{"last_testcase"}.getStr
    let expectedOutput = res{"expected_output"}.getStr
    if proj.appendTestCase(lastTestCase, expectedOutput):
      proj.openInEditor(proj.testInputFn)
      proj.openInEditor(proj.testOutputFn)
    return

  # Accepted
  showRuntimeMemory(res)

  if proj.isInContest:
    let rank = waitFor client.contestMyRanking(proj.contestSlug)
    showRank(rank)

  true
