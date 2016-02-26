class PullRequest
  constructor: (@id, @payload) ->
    @htmlUrl     = @payload.html_url
    @name        = @payload.repository.name
    @title       = @payload.title
    @ref         = @payload.head.ref
    @merged      = @payload.merged
    @mergedBy    = @payload.merged_by.login
    @state       = @payload.state
    @number      = @payload.number
    @repoName    = @payload.repository.full_name
    @labels      = @payload.labels
    @body        = @payload.body
    @authorName  = @payload.user.login
    @authorLink  = @payload.user.html_url
    @authorIcon  = @payload.user.avatar_url
    @commits     = @payload.commits
    @changed     = @payload.changed_files
    @additions   = @payload.additions
    @deletions   = @payload.deletions

  refUrl: ->
    "#{@htmlUrl}/files"

  attachmentColor: ->
    if @labels?[0]
      @labels[0].color
    else if @merged?
      "#6e5494"
    else
      switch @state
        when "closed"
          "#bd2c00"
        else
          "good"

  stateString: ->
    @state.charAt(0).toUpperCase() + @state.slice(1)

  commitsString: ->
    if @commits == 1
      "#{@commits} commit"
    else
      "#{@commits || 0} commits"

  mergedCommitsString: ->
    if @merged
      "#{commitsString} merged by #{@mergedBy}"
    else
      "#{commitsString} unmerged"

  bodyString: ->
    if obj.body.length > 80
      obj.body.substring(0,80) + "..."
    else
      obj.body

  toAttachment: ->
    fields = [{
      title: @stateString()
      value: @mergedCommitsString()
      short: true
    }, {
      title: "#{@changed} files (++#{@additions} / --#{@deletions})"
      value: "<#{@refUrl()}|#{@ref}>"
      short: true
    }]


    return {
      fallback: "[#{@repoName}] Pull Request ##{@number} (#{@stateString}): #{@title} #{@htmlUrl}"
      pretext: "[#{@repoName}] Pull Request ##{@number}"
      title: @title
      title_link: @htmlUrl
      text: @bodyString()
      color: @attachmentColor()
      author_name: @authorName
      author_link: @authorLink
      author_icon: @authorIcon
      fields: fields
    }
