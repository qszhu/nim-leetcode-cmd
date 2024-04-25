import common



proc questionTranslations*(client: AsyncHttpClient,
  host: Uri,
  titleSlug: string,
): Future[JsonNode] {.async.} =
  let url = host / "graphql/"
  let body = %*{
    "operationName": "questionTranslations",
    "query": """
query questionTranslations($titleSlug: String!) {
  question(titleSlug: $titleSlug) {
    translatedTitle
    translatedContent
  }
}
""",
    "variables": %*{
      "titleSlug": titleSlug
    }
  }

  let res = await client.request(url, httpMethod = HttpPost, body = $body)
  return (await res.body).parseJson
