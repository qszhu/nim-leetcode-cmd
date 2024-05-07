import common



proc questionTopicsList*(client: AsyncHttpClient,
  host: Uri,
  questionSlug: string,
  orderBy: string,
  first: int,
  skip: int,
  tagSlugs: seq[string],
  userInput: string,
): Future[JsonNode] {.async.} =
  let url = host / "graphql/"
  let body = %*{
    "operationName": "questionTopicsList",
    "query": """
query questionTopicsList($questionSlug: String!, $skip: Int, $first: Int, $orderBy: SolutionArticleOrderBy, $userInput: String, $tagSlugs: [String!]) {
  questionSolutionArticles(
    questionSlug: $questionSlug
    skip: $skip
    first: $first
    orderBy: $orderBy
    userInput: $userInput
    tagSlugs: $tagSlugs
  ) {
    totalNum
    edges {
      node {
        ipRegion
        rewardEnabled
        canEditReward
        uuid
        title
        slug
        sunk
        chargeType
        status
        identifier
        canEdit
        canSee
        reactionType
        hasVideo
        favoriteCount
        upvoteCount
        reactionsV2 {
          count
          reactionType
        }
        tags {
          name
          nameTranslated
          slug
          tagType
        }
        createdAt
        thumbnail
        author {
          username
          profile {
            userAvatar
            userSlug
            realName
            reputation
          }
        }
        summary
        topic {
          id
          commentCount
          viewCount
          pinned
        }
        byLeetcode
        isMyFavorite
        isMostPopular
        isEditorsPick
        hitCount
        videosInfo {
          videoId
          coverUrl
          duration
        }
      }
    }
  }
}
""",
    "variables": %*{
      "first": first,
      "orderBy": orderBy,
      "questionSlug": questionSlug,
      "skip": skip,
      "tagSlugs": tagSlugs,
      "userInput": userInput,
    }
  }

  let res = await client.request(url, httpMethod = HttpPost, body = $body)
  return (await res.body).parseJson
