import common



proc contestHistory*(client: AsyncHttpClient,
  host: Uri,
  pageNum: int,
  pageSize: int,
): Future[JsonNode] {.async.} =
  let url = host / "graphql/"
  let body = %*{
    "operationName": "contestHistory",
    "query": """
query contestHistory($pageNum: Int!, $pageSize: Int) {
  contestHistory(pageNum: $pageNum, pageSize: $pageSize) {
    totalNum
    contests {
      containsPremium
      title
      cardImg
      titleSlug
      description
      startTime
      duration
      originStartTime
      isVirtual
      company {
        watermark
        __typename
      }
      isEeExamContest
      __typename
    }
    __typename
  }
}
""",
    "variables": %*{
      "pageNum": pageNum,
      "pageSize": pageSize,
    }
  }

  let res = await client.request(url, httpMethod = HttpPost, body = $body)
  return (await res.body).parseJson
