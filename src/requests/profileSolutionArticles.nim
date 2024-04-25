import common



proc profileSolutionArticles*(client: AsyncHttpClient,
  host: Uri,
  userSlug: string,
  first: int,
  skip: int,
): Future[JsonNode] {.async.} =
  let url = host / "graphql/"
  let body = %*{
    "operationName": "profileSolutionArticles",
    "query": """
query profileSolutionArticles($userSlug: String!, $skip: Int, $first: Int) {
  solutionArticles(userSlug: $userSlug, skip: $skip, first: $first) {
    pageInfo {
      hasNextPage
    }
    edges {
      node {
        title
        slug
        createdAt
        status
        question {
          titleSlug
          translatedTitle
          questionFrontendId
        }
        upvoteCount
        topic {
          viewCount
        }
      }
    }
  }
}
""",
    "variables": %*{
      "first": first,
      "skip": skip,
      "userSlug": userSlug
    }
  }

  let res = await client.request(url, httpMethod = HttpPost, body = $body)
  return (await res.body).parseJson
