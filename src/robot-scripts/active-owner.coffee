# Description
#   Let Hubot keep track of who is on AO duty for each team
#
# Configuration:
#  HUBOT_REVIEW_NEEDED_LABEL (Hubot messages all AOs when PR gets this label)
#  add GitHub webhook with pull_request events to <hubot server>:8080/hubot/gh
#
# Commands:
#   hubot show AOs - displays the current active owner for each team
#   hubot show review list - displays the list of PRs currently needing reveiw
#   hubot assign [user] as AO for [team] - assign a user as AO for a team
#   hubot I'm AO for [team]- assign yourself as AO for a team
#   hubot Add [team] to teams - add a team
moment = require 'moment'
_ = require 'lodash'
AOHelper = require('../ActiveOwnerHelper')

module.exports = (robot) ->

  robot.brain.data.teams ||= {}
  robot.brain.data.reviews ||= {}
  helper = new AOHelper robot

  aoStatus = (team) ->
    if team.aoUserId?
      aoName = robot.brain.userForId(team.aoUserId).name
      "#{aoName} has been active owner on #{team.name} " +
      "for #{moment(team.aoUserAssignedDt).fromNow(true)}"
    else
      "* #{team.name} has no active owner! " +
      "Use: 'Assign <user> as AO for <team>'."

  robot.respond /(list|show) (active owners|AO's|AOs)/i, (msg) ->
    teams = robot.brain.data.teams
    if Object.keys(teams).length == 0
      response = "Sorry, I'm not keeping track of any teams or their AOs.\n" +
      "Get started with 'Add <team name> to teams'."
      return msg.send response
    aoDescription = (team) ->
      if team.aoUserId?
        aoName = robot.brain.userForId(team.aoUserId).name
        "#{aoName} has been active owner on #{team.name} " +
        "for #{moment(team.aoUserAssignedDt).fromNow(true)}"
      else
        "* #{team.name} has no active owner! "
    aoDescriptions = (aoDescription(teams[prop]) for prop of teams)
    msg.send "AOs:\n" + aoDescriptions.join("\n") + "\n\nUse: 'Assign <user> as AO for <team>' to assign an AO."

  robot.respond /(list|show) review list/i, (msg) ->
    reviews = robot.brain.data.reviews
    if Object.keys(reviews).length == 0
      response = "Nothing needs review as far as I know."
      return msg.send response
    prDescription = (pr) ->
      "Added #{moment(pr.reviewNeededDt).fromNow()}: #{pr.url}"
    prDescriptionList = (prDescription(reviews[prop]) for prop of reviews)
    msg.send "PRs in need of review:\n" + prDescriptionList.join("\n")

  robot.respond /add ([a-z0-9 ]+) to teams/i, (msg) ->
    teamName = msg.match[1]
    if helper.getTeam(teamName)
      return msg.send "#{teamName} already being tracked."
    helper.addTeam(teamName)
    msg.send "#{teamName} added."

  robot.respond /(delete|remove) ([a-z0-9 ]+) from teams/i, (msg) ->
    teamName = msg.match[2]
    if helper.getTeam(teamName)
      helper.removeTeam(teamName)
      return msg.send "Removed #{teamName} from tracked teams."
    msg.send "I wasn't tracking #{teamName}."

  robot.respond /(delete|remove) review ([a-z0-9/]+) from review list/i,
    (msg) ->
      reviewKey = msg.match[2]
      if helper.getReview(reviewKey)
        helper.removeReview(reviewKey)
      return msg.send "Removed #{reviewKey} from review list."
      msg.send "I wasn't tracking #{reviewKey}."

  robot.respond /assign ([a-z0-9 -@]+) as AO for ([a-z0-9 ]+)/i, (msg) ->
    userId = helper.getIdForName msg.match[1]
    teamName = msg.match[2]
    helper.assignTeam userId, teamName, msg
  
  robot.respond /I'm AO for ([a-z0-9 ]+)/i, (msg) ->
    teamName = msg.match[1]
    helper.assignTeam msg.message.user.id, teamName, msg
