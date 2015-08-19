path = require 'path'
chai = require 'chai'
expect = chai.expect
_ = require 'lodash'
Robot = require 'hubot/src/robot'
Brain = require 'hubot/src/brain'
TextMessage = require('hubot/src/message').TextMessage

# to avoid EventEmitter memory leak warning
process.setMaxListeners(20)

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

  describe 'on review-complete events', ->
    beforeEach (done) ->
      robot = @robot
      user = @user
      @robot.receive (new TextMessage user, 'TestHubot add Team America to teams'), ->
      	robot.receive (new TextMessage user, 'TestHubot add The Mighty Ducks to teams'), ->
      		robot.receive (new TextMessage user, "TestHubot I'm AO for Team America"), ->
      			robot.emit 'review-needed',
        			url: 'http://www.github.com/a/b/pull/1'
        			repo: 'a/b'
        			number: 1
        			key: 'a/b/1'
        		done()

      

    it 'should message AOs that review is no longer needed, with PR link', (done) ->
      adapter = @adapter
      robot = @robot
      @robot.receive (new TextMessage @user, "TestHubot assign Charlie as AO for The Mighty Ducks"), ->
        verifyAlertedUsers = ->
          if alertedUsers.indexOf('1') >= 0 && alertedUsers.indexOf('2') >= 0
            done()
        finished = _.after 2, verifyAlertedUsers
        alertedUsers = []
        adapter.on 'reply', (envelope, strings) ->
          console.log("reply")
          expect(strings[0]).to.equal("Review no longer needed for http://www.github.com/a/b/pull/1. The PR either was closed or review label was removed.")
          alertedUsers.push(envelope.id)
          finished()
        console.log("potential-review-complete")
        robot.emit 'potential-review-complete',
          url: 'http://www.github.com/a/b/pull/1'
          repo: 'a/b'
          number: 1
          key: 'a/b/1'

    it 'should remove the PR that is no longer in need of review', (done) ->
      @adapter.on 'reply', (envelope, strings) ->
        expect(@robot.brain.data.reviews).not.to.contain.keys('a/b/1')
        done()
      @robot.emit 'potential-review-complete',
        url: 'http://www.github.com/a/b/pull/1'
        repo: 'a/b'
        number: 1
        key: 'a/b/1'
