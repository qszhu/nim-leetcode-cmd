import common



proc discussTopic*(client: AsyncHttpClient,
  host: Uri,
  slug: string,
): Future[JsonNode] {.async.} =
  let url = host / "graphql/"
  let body = %*{
    "operationName": "discussTopic",
    "query": """
query discussTopic($slug: String) {
  solutionArticle(slug: $slug, orderBy: DEFAULT) {
    ...solutionArticle
    content
    next {
      slug
      title
    }
    prev {
      slug
      title
    }
  }
}
fragment solutionArticle on SolutionArticleNode {
  ipRegion
  rewardEnabled
  canEditReward
  uuid
  title
  content
  slateValue
  slug
  sunk
  chargeType
  status
  identifier
  canEdit
  canSee
  reactionType
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
    isDiscussAdmin
    isDiscussStaff
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
    subscribed
    commentCount
    viewCount
    post {
      id
      status
      voteStatus
      isOwnPost
    }
  }
  byLeetcode
  isMyFavorite
  isMostPopular
  favoriteCount
  isEditorsPick
  hitCount
  videosInfo {
    videoId
    coverUrl
    duration
  }
  question {
    titleSlug
    questionFrontendId
  }
}
""",
    "variables": %*{
      "slug": slug,
    }
  }
  let res = await client.request(url, httpMethod = HttpPost, body = $body)
  return (await res.body).parseJson
