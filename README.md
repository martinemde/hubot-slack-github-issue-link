# hubot-slack-github-issue-link

A hubot script that posts detailed slack attachments for mentioned github issues and pull requests

This script only emits Slack attachments which are crafted specifically for the Slack API.

See [`src/slack-github-issue-link.coffee`](src/slack-github-issue-link.coffee) for full documentation.

![Example output](https://github.com/martinemde/hubot-slack-github-issue-link/blob/master/example.png)


## Installation

In hubot project repo, run:

`npm install hubot-slack-github-issue-link --save`

Then add **hubot-slack-github-issue-link** to your `external-scripts.json`:

```json
[
  "hubot-slack-github-issue-link"
]
```

