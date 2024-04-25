import common



proc languageList*(client: AsyncHttpClient,
  host: Uri,
): Future[JsonNode] {.async.} =
  let url = host / "graphql/"
  let body = %*{
    "operationName": "languageList",
    "query": """
query languageList {
  languageList {
    id
    name
  }
}
""",
  }

  let res = await client.request(url, httpMethod = HttpPost, body = $body)
  return (await res.body).parseJson
