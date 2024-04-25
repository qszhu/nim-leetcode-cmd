import common



proc questionEditorData*(client: AsyncHttpClient,
  host: Uri,
  titleSlug: string,
): Future[JsonNode] {.async.} =
  let url = host / "graphql/"
  let body = %*{
    "operationName": "questionEditorData",
    "query": """
query questionEditorData($titleSlug: String!) {
  question(titleSlug: $titleSlug) {
    questionId
    questionFrontendId
    codeSnippets {
      lang
      langSlug
      code
    }
    envInfo
    enableRunCode
    hasFrontendPreview
    frontendPreviews
  }
}
""",
    "variables": %*{
      "titleSlug": titleSlug
    }
  }

  let res = await client.request(url, httpMethod = HttpPost, body = $body)
  return (await res.body).parseJson
