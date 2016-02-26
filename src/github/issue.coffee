class Issue
  constructor: (@id, @payload) ->
    @htmlUrl     = @payload.html_url
    @name        = @payload.repository.name
    @title       = @payload.title
    @state       = @payload.state
    @number      = @payload.number
    @repoName    = @payload.repository.full_name
    @labels      = @payload.labels
    @body        = @payload.body
    @authorName  = @payload.user.login
    @authorLink  = @payload.user.html_url
    @authorIcon  = @payload.user.avatar_url

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

  bodyString: ->
    if obj.body.length > 80
      obj.body.substring(0,80) + "..."
    else
      obj.body

  toAttachment: ->

    return {
      fallback: "[#{@repoName}] Issue ##{@number} (#{@stateString}): #{@title} #{@htmlUrl}"
      pretext: "[#{@repoName}] Issue ##{@number}"
      title: @title
      title_link: @htmlUrl
      text: @bodyString()
      color: @attachmentColor()
      author_name: @authorName
      author_link: @authorLink
      author_icon: @authorIcon
      fields: [{
        title: @stateString()
        short: true
      }]
    }
