path = require 'path'
chai = require 'chai'
expect = chai.expect
_ = require 'lodash'
Robot = require 'hubot/src/robot'
Brain = require 'hubot/src/brain'
TextMessage = require('hubot/src/message').TextMessage

describe 'Hubot with active-owner script', ->
  beforeEach (done) ->
    @robot = new Robot null, 'mock-adapter', true, 'TestHubot'
    @adapter = @robot.adapter
    @adapter.on 'connected', ->
      @robot.loadFile path.resolve('.', 'src', 'robot-scripts'), 'active-owner.coffee'
      @robot.loadFile path.resolve('.', 'src', 'robot-scripts'), 'review-needed-handler.coffee'
      @robot.loadFile path.resolve('.', 'src', 'robot-scripts'), 'review-complete-handler.coffee'
    @robot.run()
    @user = @robot.brain.userForId '1',
      name: '@Gary'
      room: '1'
    @robot.brain.userForId '2',
      name: 'Charlie'
      room: '1'
    done()

  afterEach ->
    @robot.server.close()
    @robot.shutdown

  describe 'on review-needed events', ->
    it 'should message AOs with PR link', (done) ->
      adapter = @adapter
      user = @user
      robot = @robot
      robot.receive (new TextMessage user, 'TestHubot add Team America to teams'), ->
        robot.receive (new TextMessage user, 'TestHubot add The Mighty Ducks to teams'), ->
            robot.receive (new TextMessage user, 'TestHubot add Team Knight Rider to teams'), ->
              robot.receive (new TextMessage user, "TestHubot I'm AO for Team America"), ->
                robot.receive (new TextMessage user, "TestHubot assign Charlie as AO for The Mighty Ducks"), ->
                  verifyAlertedUsers = ->
                    if alertedUsers.indexOf('1') >= 0 && alertedUsers.indexOf('2') >= 0
                      done()
                  finished = _.after 2, verifyAlertedUsers
                  alertedUsers = []

                  adapter.on 'reply', (envelope, strings) ->
                    expect(strings[0]).to.equal("Rapid Response needs a review of http://www.github.com/a/b/pull/1")
                    alertedUsers.push(envelope.id)
                    finished()
                  robot.emit 'review-needed',
                    url: 'http://www.github.com/a/b/pull/1'
                    repo: 'a/b'
                    number: 1
                    key: 'a/b/1'

    it 'should persist the PR needing review', (done) ->
      robot = @robot
      adapter = @adapter
      user = @user
      robot.receive (new TextMessage user, 'TestHubot add Team America to teams'), ->
        robot.receive (new TextMessage user, "TestHubot I'm AO for Team America"), ->
          adapter.on 'reply', (envelope, strings) ->
            expect(@robot.brain.data.reviews).to.contain.keys('a/b/1')
            expect(@robot.brain.data.reviews['a/b/1'].url).to.equal('http://www.github.com/a/b/pull/1')
            expect(@robot.brain.data.reviews['a/b/1'].repo).to.equal('a/b')
            expect(@robot.brain.data.reviews['a/b/1'].number).to.equal(1)
            done()
          robot.emit 'review-needed',
            url: 'http://www.github.com/a/b/pull/1'
            repo: 'a/b'
            number: 1
            key: 'a/b/1'

