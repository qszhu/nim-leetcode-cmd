import ../../lib/leetcode/lcClient
import ../../projects/projects
import ../../nlccrcs



const STATUS_ACCEPTED = "Accepted"

proc showRank(client: LcClient, contestSlug: string) =
  let rank = waitFor client.contestMyRanking(contestSlug)
  echo "Solved: ", rank["my_solved"].getElems.len
  echo "Score: ", rank["my_rank"]["score"].getInt
  echo "Rank: ", rank["my_rank"]["rank_v2"].getInt

proc submitCmd*(proj: BaseProject): bool =
  let client = newLcClient()
  client.setToken(nlccrc.getLeetCodeSession)

  let res = proj.submit(client)

  # Runtime Error
  if not res["run_success"].getBool:
    echo res["full_runtime_error"].getStr
    return

  let status = res["status_msg"].getStr
  echo status
  echo "Passed cases: ", res["total_correct"].getInt, "/", res["total_testcases"].getInt

  # Wrong Answer, etc.
  if status != STATUS_ACCEPTED:
    let lastTestCase = res["last_testcase"].getStr
    proj.appendTestCase(lastTestCase)
    return

  # Accepted
  echo "Runtime: ", res["status_runtime"].getStr
  echo "Memory: ", res["status_memory"].getStr

  showRank(client, proj.contestSlug)

  true
