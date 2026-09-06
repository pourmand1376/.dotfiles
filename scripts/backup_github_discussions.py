#!/usr/bin/env python3

import json
import subprocess
import sys
import time
from pathlib import Path

OWNER = "amir-pourmand"
REPO = "hugo-papermod-farsi-template"
OUT = Path("github-discussions-backup")

OUT.mkdir(parents=True, exist_ok=True)


def graphql(query, variables=None):
    args = ["gh", "api", "graphql", "-f", f"query={query}"]

    for key, value in (variables or {}).items():
        if value is not None:
            args += ["-F", f"{key}={value}"]

    while True:
        result = subprocess.run(
            args,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )

        if result.returncode == 0:
            return json.loads(result.stdout)

        print(result.stderr, file=sys.stderr)
        print("Retrying GitHub API request...", file=sys.stderr)
        time.sleep(3)


DISCUSSIONS_QUERY = r"""
query($owner: String!, $repo: String!, $cursor: String) {
  repository(owner: $owner, name: $repo) {
    id
    name
    nameWithOwner
    url
    description

    discussionCategories(first: 100) {
      nodes {
        id
        name
        description
        emoji
        isAnswerable
        slug
      }
    }

    discussions(first: 50, after: $cursor) {
      totalCount
      pageInfo {
        hasNextPage
        endCursor
      }

      nodes {
        id
        databaseId
        number
        title
        body
        bodyHTML
        bodyText
        url
        resourcePath

        createdAt
        updatedAt
        publishedAt
        lastEditedAt

        closed
        closedAt
        locked
        activeLockReason
        stateReason

        upvoteCount

        authorAssociation
        author {
          login
          url
          avatarUrl
          ... on User {
            name
          }
        }

        editor {
          login
          url
        }

        category {
          id
          name
          description
          emoji
          isAnswerable
          slug
        }

        answer {
          id
          databaseId
          url
        }

        answerChosenAt
        answerChosenBy {
          login
          url
        }

        labels(first: 100) {
          nodes {
            id
            name
            description
            color
          }
        }

        reactionGroups {
          content
          users {
            totalCount
          }
        }

        poll {
          id
          question
          totalVoteCount
          options(first: 100) {
            nodes {
              id
              option
              totalVoteCount
            }
          }
        }

        comments(first: 1) {
          totalCount
        }
      }
    }
  }
}
"""


COMMENTS_QUERY = r"""
query($id: ID!, $cursor: String) {
  node(id: $id) {
    ... on Discussion {
      comments(first: 50, after: $cursor) {
        totalCount

        pageInfo {
          hasNextPage
          endCursor
        }

        nodes {
          id
          databaseId
          body
          bodyHTML
          bodyText

          url
          resourcePath

          createdAt
          updatedAt
          publishedAt
          lastEditedAt
          deletedAt

          createdViaEmail
          includesCreatedEdit

          authorAssociation

          author {
            login
            url
            avatarUrl
            ... on User {
              name
            }
          }

          editor {
            login
            url
          }

          isAnswer
          isMinimized
          minimizedReason

          upvoteCount

          reactionGroups {
            content
            users {
              totalCount
            }
          }

          replies(first: 1) {
            totalCount
          }
        }
      }
    }
  }
}
"""


REPLIES_QUERY = r"""
query($id: ID!, $cursor: String) {
  node(id: $id) {
    ... on DiscussionComment {
      replies(first: 50, after: $cursor) {
        totalCount

        pageInfo {
          hasNextPage
          endCursor
        }

        nodes {
          id
          databaseId

          body
          bodyHTML
          bodyText

          url
          resourcePath

          createdAt
          updatedAt
          publishedAt
          lastEditedAt
          deletedAt

          createdViaEmail
          includesCreatedEdit

          authorAssociation

          author {
            login
            url
            avatarUrl
            ... on User {
              name
            }
          }

          editor {
            login
            url
          }

          isAnswer
          isMinimized
          minimizedReason

          upvoteCount

          replyTo {
            id
            databaseId
            url
          }

          reactionGroups {
            content
            users {
              totalCount
            }
          }
        }
      }
    }
  }
}
"""


def get_all_discussions():
    result = []
    cursor = None
    repository_metadata = None

    while True:
        data = graphql(
            DISCUSSIONS_QUERY,
            {
                "owner": OWNER,
                "repo": REPO,
                "cursor": cursor,
            },
        )

        repo = data["data"]["repository"]

        if repository_metadata is None:
            repository_metadata = {
                "id": repo["id"],
                "name": repo["name"],
                "nameWithOwner": repo["nameWithOwner"],
                "url": repo["url"],
                "description": repo["description"],
                "discussionCategories": repo["discussionCategories"]["nodes"],
            }

        connection = repo["discussions"]
        result.extend(connection["nodes"])

        print(
            f"Discussions: {len(result)}/{connection['totalCount']}",
            file=sys.stderr,
        )

        if not connection["pageInfo"]["hasNextPage"]:
            break

        cursor = connection["pageInfo"]["endCursor"]

    return repository_metadata, result


def get_comments(discussion_id):
    comments = []
    cursor = None

    while True:
        data = graphql(
            COMMENTS_QUERY,
            {
                "id": discussion_id,
                "cursor": cursor,
            },
        )

        connection = data["data"]["node"]["comments"]
        comments.extend(connection["nodes"])

        if not connection["pageInfo"]["hasNextPage"]:
            break

        cursor = connection["pageInfo"]["endCursor"]

    return comments


def get_replies(comment_id):
    replies = []
    cursor = None

    while True:
        data = graphql(
            REPLIES_QUERY,
            {
                "id": comment_id,
                "cursor": cursor,
            },
        )

        connection = data["data"]["node"]["replies"]
        replies.extend(connection["nodes"])

        if not connection["pageInfo"]["hasNextPage"]:
            break

        cursor = connection["pageInfo"]["endCursor"]

    return replies


def safe_filename(value):
    return "".join(c if c.isalnum() or c in "-_." else "_" for c in value)[:120]


def markdown_export(discussion):
    lines = []

    lines.append(f"# {discussion['title']}")
    lines.append("")
    lines.append(f"- Discussion: #{discussion['number']}")
    lines.append(f"- URL: {discussion['url']}")
    lines.append(f"- Created: {discussion['createdAt']}")
    lines.append(f"- Updated: {discussion['updatedAt']}")

    author = discussion.get("author")
    if author:
        lines.append(f"- Author: @{author['login']}")

    category = discussion.get("category")
    if category:
        lines.append(f"- Category: {category['name']}")

    lines.append("")
    lines.append(discussion["body"])
    lines.append("")

    for comment in discussion["comments"]:
        lines.append("---")
        lines.append("")

        author = comment.get("author")
        author_name = f"@{author['login']}" if author else "[deleted]"

        lines.append(f"## Comment — {author_name}")
        lines.append("")
        lines.append(f"Created: {comment['createdAt']}")
        lines.append("")
        lines.append(comment["body"])
        lines.append("")

        for reply in comment.get("replies", []):
            reply_author = reply.get("author")
            reply_name = f"@{reply_author['login']}" if reply_author else "[deleted]"

            lines.append(f"### Reply — {reply_name}")
            lines.append("")
            lines.append(f"Created: {reply['createdAt']}")
            lines.append("")
            lines.append(reply["body"])
            lines.append("")

    return "\n".join(lines)


def main():
    metadata, discussions = get_all_discussions()

    (OUT / "repository.json").write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    discussions_dir = OUT / "discussions"
    discussions_dir.mkdir(exist_ok=True)

    complete = []

    for index, discussion in enumerate(discussions, start=1):
        print(
            f"[{index}/{len(discussions)}] "
            f"#{discussion['number']} {discussion['title']}",
            file=sys.stderr,
        )

        comments = get_comments(discussion["id"])

        for comment in comments:
            comment["replies"] = get_replies(comment["id"])

        discussion["comments"] = comments
        complete.append(discussion)

        stem = f"{discussion['number']:05d}-{safe_filename(discussion['title'])}"

        (discussions_dir / f"{stem}.json").write_text(
            json.dumps(
                discussion,
                ensure_ascii=False,
                indent=2,
            ),
            encoding="utf-8",
        )

        (discussions_dir / f"{stem}.md").write_text(
            markdown_export(discussion),
            encoding="utf-8",
        )

    (OUT / "all-discussions.json").write_text(
        json.dumps(
            complete,
            ensure_ascii=False,
            indent=2,
        ),
        encoding="utf-8",
    )

    print(
        f"\nBackup complete: {OUT.resolve()}",
        file=sys.stderr,
    )


if __name__ == "__main__":
    main()
