import ../../lib/leetcode/lcClient
import ../../projects/projects
import ../../nlccrcs
import utils
import ../consts



proc submitCmd*(proj: BaseProject): bool =
  let client = newLcClient()
  client.setToken(nlccrc.getLeetCodeSession)

  let res = proj.submit(client)

  # Runtime Error
  if showRuntimeError(res): return

  let status = showStatus(res)
  showPassedCases(res)

  # Wrong Answer, etc.
  if status != STATUS_ACCEPTED:
    let lastTestCase = res{"last_testcase"}.getStr
    if lastTestCase.len > 0:
      proj.appendTestCase(lastTestCase)
    return

  # Accepted
  showRuntimeMemory(res)

  let rank = waitFor client.contestMyRanking(proj.contestSlug)
  showRank(rank)

  true
