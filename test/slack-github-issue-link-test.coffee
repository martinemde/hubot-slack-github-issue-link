chai = require 'chai'
sinon = require 'sinon'
chai.use require 'sinon-chai'

expect = chai.expect

describe 'slack-github-issue-link', ->
  beforeEach ->
    @robot =
      respond: sinon.spy()
      hear: sinon.spy()
      emit: sinon.spy()

    require('../src/slack-github-issue-link')(@robot)

  it 'registers a respond listener', ->
    expect(@robot.respond).to.have.been.calledWith(/hello/)

  it 'registers a hear listener', ->
    expect(@robot.hear).to.have.been.calledWith(/(https:\/\/github.com\/\/?)?((\S*|^)?(#|\/issues?\/|\/pulls?\/)(\d+)).*/i, id: "hubot-slack-github-issue-link")

  it 'registers a hear listener', ->
    expect(@robot.emit).to.have.been.calledWith('slack-attachment')
