import common



proc consolePanelConfig*(client: AsyncHttpClient,
  host: Uri,
  titleSlug: string,
): Future[JsonNode] {.async.} =
  let url = host / "graphql/"
  let body = %*{
    "operationName": "consolePanelConfig",
    "query": """
query consolePanelConfig($titleSlug: String!) {
  question(titleSlug: $titleSlug) {
    questionId
    questionFrontendId
    questionTitle
    enableRunCode
    enableSubmit
    enableTestMode
    jsonExampleTestcases
    exampleTestcases
    metaData
    sampleTestCase
  }
}
""",
    "variables": %*{
      "titleSlug": titleSlug
    }
  }

  let res = await client.request(url, httpMethod = HttpPost, body = $body)
  return (await res.body).parseJson
