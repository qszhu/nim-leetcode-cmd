import common



proc boundTopicId*(client: AsyncHttpClient,
  host: Uri,
  titleSlug: string,
): Future[JsonNode] {.async.} =
  let url = host / "graphql/"
  let body = %*{
    "operationName": "boundTopicId",
    "query": """
query boundTopicId($titleSlug: String!) {
  question(titleSlug: $titleSlug) {
    boundTopicId
  }
}
""",
    "variables": %*{
      "titleSlug": titleSlug
    }
  }

  let res = await client.request(url, httpMethod = HttpPost, body = $body)
  return (await res.body).parseJson
