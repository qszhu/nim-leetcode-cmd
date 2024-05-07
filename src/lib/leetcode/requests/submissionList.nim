import common



proc submissionList*(client: AsyncHttpClient,
  host: Uri,
  questionSlug: string,
  offset: int,
  limit: int,
  lastKey: string,
  status: string,
): Future[JsonNode] {.async.} =
  let url = host / "graphql/"
  var body = %*{
    "operationName": "submissionList",
    "query": """
query submissionList($offset: Int!, $limit: Int!, $lastKey: String, $questionSlug: String!, $lang: String, $status: SubmissionStatusEnum) {
  submissionList(
    offset: $offset
    limit: $limit
    lastKey: $lastKey
    questionSlug: $questionSlug
    lang: $lang
    status: $status
  ) {
    lastKey
    hasNext
    submissions {
      id
      title
      status
      statusDisplay
      lang
      langName: langVerboseName
      runtime
      timestamp
      url
      isPending
      memory
      submissionComment {
        comment
        flagType
      }
    }
  }
}
""",
    "variables": %*{
      "lastKey": nil,
      "limit": limit,
      "offset": offset,
      "questionSlug": questionSlug,
      "status": nil,
    }
  }
  if lastKey.len > 0: body["variables"]["lastKey"] = %lastKey
  if status.len > 0: body["variables"]["status"] = %status
  let res = await client.request(url, httpMethod = HttpPost, body = $body)
  return (await res.body).parseJson
