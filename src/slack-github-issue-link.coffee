# Description:
#   Slack Github issue link looks for #nnn, and pull or issue urls
#   and posts an informative Slack attachment that show detailed information
#   about the issue or pull request.
#
#   Eg. "Hey guys check out #273"
#   Eg. "Merge please: https://github.com/martinemde/hubot-slack-github-issue-link/pull/1"
#
#   Defaults to issues in HUBOT_GITHUB_REPO when only matching #NNN,
#   unless a repo is specified Eg. "Hey guys, check out awesome-repo#273"
#
#   If HUBOT_GITHUB_IGNORE_NON_ORG_LINKS is set, this scirpt will ignore
#   links outside of the org set in HUBOT_GITHUB_ORG, and all non-private
#   project links to avoid double posting public projects. Slackbot will
#   post (less pretty) links to public github urls, which cannot be avoided.
#
# Dependencies:
#   "githubot": "0.4.x"
#
# Configuration:
#   HUBOT_GITHUB_REPO
#   HUBOT_GITHUB_TOKEN
#   HUBOT_GITHUB_API
#   HUBOT_GITHUB_HOSTNAME
#   HUBOT_GITHUB_ISSUE_LINK_IGNORE_USERS
#   HUBOT_GITHUB_IGNORE_NON_ORG_LINKS
#   HUBOT_GITHUB_ORG
#
# Commands:
#   #nnn - link to GitHub issue nnn for HUBOT_GITHUB_REPO project
#   repo#nnn - link to GitHub issue nnn for repo project
#   user/repo#nnn - link to GitHub issue nnn for user/repo project
#   https://github.com/org/repo/issue/1234 - show details for github issue
#   https://github.com/org/repo/pull/1234 - show details for github pullrequest
#
# Notes:
#   HUBOT_GITHUB_HOSTNAME, if set, expects the scheme (https://). Defaults to "https://github.com/"
#   HUBOT_GITHUB_API allows you to set a custom URL path (for Github enterprise users) but the links won't match your domain since this only looks for github.com domains. I've never used github enterprise
#
# Author:
#   Martin Emde <me@martinemde.com>
#   Originally by tenfef

module.exports = (robot) ->
  github = require("githubot")(robot)

  githubIgnoreUsers = process.env.HUBOT_GITHUB_ISSUE_LINK_IGNORE_USERS or "github|hubot"
  githubHostname = process.env.HUBOT_GITHUB_HOSTNAME or "https://github.com/"
  githubProjectMatch =
    if process.env.HUBOT_GITHUB_IGNORE_NON_ORG_LINKS != undefined && process.env.HUBOT_GITHUB_ORG != undefined
      "#{process.env.HUBOT_GITHUB_ORG}/"
    else
      "\\S"

  githubIssueUrlPattern = ///(#{githubHostname}\/?)?((#{githubProjectMatch}*|^)?(#|/issues?/|/pulls?/)(\d+)).*///i

  attachmentColor = (obj) ->
    if obj.labels && obj.labels[0]
      color = obj.labels[0].color
    else if obj.merged
      color = "#6e5494"
    else
      switch obj.state
        when "closed"
          color = "#bd2c00"
        else
          color = "good"


  makeAttachment = (obj, type, repo_name) ->
    issue_title = obj.title
    html_url    = obj.html_url
    body        = if obj.body.length > 80 then obj.body.substring(0,80) + "..." else obj.body
    color       = attachmentColor(obj)
    state       = obj.state.charAt(0).toUpperCase() + obj.state.slice(1)

    if obj.commits
      if obj.commits == 1
        commits = "commit"
      else
        commits = "commits"
      merged = if obj.merged then "merged by #{obj.merged_by.login}" else "unmerged"
      merged_commits = "#{obj.commits || 0} #{commits} #{merged}"
      fields = [{
        title: state
        value: merged_commits
        short: true
      }]
    else
      fields = [{
        title: state
        short: true
      }]

    if obj.head && obj.head.ref
      fields.push
        title: "#{obj.changed_files} files (++#{obj.additions} / --#{obj.deletions})"
        value: "<#{obj.html_url}/files|#{obj.head.ref}>"
        short: true

    return {
      fallback: "[#{repo_name}] #{type} ##{obj.number} (#{state}): #{issue_title} #{html_url}"
      pretext: "[#{repo_name}] #{type} ##{obj.number}"
      title: issue_title
      title_link: html_url
      text: body
      color: color
      author_name: obj.user.login
      author_link: obj.user.html_url
      author_icon: obj.user.avatar_url
      fields: fields
    }

  matchRepo = (repo) ->
    if repo == undefined
      return github.qualified_repo process.env.HUBOT_GITHUB_REPO
    else if process.env.HUBOT_GITHUB_IGNORE_NON_ORG_LINKS && process.env.HUBOT_GITHUB_ORG && !repo.match(new RegExp(process.env.HUBOT_GITHUB_ORG, "i"))
      return undefined
    else
      return github.qualified_repo repo

  robot.hear githubIssueUrlPattern, id: "hubot-slack-github-issue-link", (msg) ->
    if msg.message.user.name.match(new RegExp(githubIgnoreUsers, "gi"))
      return

    issue_number = msg.match[5]
    if isNaN(issue_number)
      return

    repo_name = matchRepo(msg.match[3])
    if repo_name == undefined
      return

    base_url = process.env.HUBOT_GITHUB_API || 'https://api.github.com'

    if msg.match[4] == undefined || msg.match[4] == '#'
      path = "/issues/"
    else
      path = msg.match[4]

    if path.match /\/pulls?\//
      type = "Pull Request"
      api_path = "pulls"
    else
      type = "Issue"
      api_path = "issues"

    api_url = "#{base_url}/repos/#{repo_name}/#{api_path}/" + issue_number

    github.get api_url, (obj) ->
      # We usually don't post public PRs, Slack will show them
      if process.env.HUBOT_GITHUB_IGNORE_NON_ORG_LINKS && obj.base?.repo?.private == false
        return

      # need to figure out how to exclude public issues

      attachment = makeAttachment(obj, type, repo_name)
      robot.emit 'slack-attachment',
        message:
          room: msg.message.room
        content: attachment
