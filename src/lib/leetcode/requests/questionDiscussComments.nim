import common



proc questionDiscussComments*(client: AsyncHttpClient,
  host: Uri,
  topicId: int,
  orderBy: string,
  numPerPage: int,
  skip: int,
): Future[JsonNode] {.async.} =
  let url = host / "graphql/"
  let body = %*{
    "operationName": "questionDiscussComments",
    "query": """
query questionDiscussComments($topicId: Int!, $orderBy: CommentOrderBy, $skip: Int!, $numPerPage: Int = 10) {
  commonTopicComments(
    topicId: $topicId
    orderBy: $orderBy
    skip: $skip
    first: $numPerPage
  ) {
    edges {
      node {
        ...commentFields
      }
    }
    totalNum
  }
}
fragment commentFields on CommentRelayNode {
  id
  ipRegion
  numChildren
  isEdited
  post {
    id
    content
    voteUpCount
    creationDate
    updationDate
    status
    voteStatus
    isOwnPost
    author {
      username
      isDiscussAdmin
      isDiscussStaff
      profile {
        userSlug
        userAvatar
        realName
      }
    }
    mentionedUsers {
      key
      username
      userSlug
      nickName
    }
  }
}
""",
    "variables": %*{
      "numPerPage": numPerPage,
      "orderBy": orderBy,
      "skip": skip,
      "topicId": topicId,
    }
  }

  let res = await client.request(url, httpMethod = HttpPost, body = $body)
  return (await res.body).parseJson
