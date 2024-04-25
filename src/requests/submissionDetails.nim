import common



proc submissionDetails*(client: AsyncHttpClient,
  host: Uri,
  submissionId: string,
): Future[JsonNode] {.async.} =
  let url = host / "graphql/"
  let body = %*{
    "operationName": "submissionDetails",
    "query": """
query submissionDetails($submissionId: ID!) {
  submissionDetail(submissionId: $submissionId) {
    code
    timestamp
    statusDisplay
    isMine
    runtimeDisplay: runtime
    memoryDisplay: memory
    memory: rawMemory
    lang
    langVerboseName
    question {
      questionId
      titleSlug
      hasFrontendPreview
    }
    user {
      realName
      userAvatar
      userSlug
    }
    runtimePercentile
    memoryPercentile
    submissionComment {
      flagType
    }
    passedTestCaseCnt
    totalTestCaseCnt
    fullCodeOutput
    testDescriptions
    testInfo
    testBodies
    stdOutput
    ... on GeneralSubmissionNode {
      outputDetail {
        codeOutput
        expectedOutput
        input
        compileError
        runtimeError
        lastTestcase
      }
    }
    ... on ContestSubmissionNode {
      outputDetail {
        codeOutput
        expectedOutput
        input
        compileError
        runtimeError
        lastTestcase
      }
    }
  }
}
""",
    "variables": %*{
      "submissionId": submissionId
    }
  }

  let res = await client.request(url, httpMethod = HttpPost, body = $body)
  return (await res.body).parseJson
