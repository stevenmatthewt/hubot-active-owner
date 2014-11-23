# Description
#   Let Hubot keep track of who is on AO duty for each team
#
# Configuration:
#  HUBOT_GITHUB_TOKEN (for notifying AOs of PRs with rr-needs-review in private repos) 
#  HUBOT_REVIEW_NEEDED_LABEL (Hubot messages all AOs when PR gets this label) 
#
# Commands:
#   hubot show|list AOs - displays the current active owner for each team
#   hubot assign [user] as AO for [team] - assign a user as AO for a team
#   hubot I'm AO for [team]- assign yourself as AO for a team
moment = require 'moment'
_ = require 'lodash'
GitHubApi = require 'github'

module.exports = (robot) ->

  robot.brain.data.teams ||= {}
  robot.brain.data.prsForReview ||= []

  # TODO: move review-* events to their own modules
  robot.on 'review-needed', (pullRequest) ->
    pr = new PullRequest(pullRequest)
    robot.brain.data.prsForReview["#{pr.repo}/#{pr.number}"] = pr
    message = "Rapid Response needs a review of #{pr.url}"
    messageAOs(message)

  robot.on 'review-no-longer-needed', (pr) ->
    delete robot.brain.data.prsForReview["#{pr.repo}/#{pr.number}"]
    message = "Review no longer needed for #{pr.url}. The PR either was closed or review label was removed."
    messageAOs(message)

  # TODO: move webhook listener and  event emission logic to its own module
  robot.router.post 'hubot/gh-issues', (req, res) ->
    robot.logger.info "issue detected via GitHub webook: #{res}"
    if res.action == 'labeled' && res.label.name == process.env.HUBOT_REVIEW_NEEDED_LABEL
      robot.logger.info "emitting review-needed event: url: #{res.issue.url}"
      robot.emit 'review-needed',
        url: res.issue.url
        repo: res.repository.full_name
        number: res.issue.number
    if reviewNoLongerNeeded res
      robot.logger.info "emitting review-no-longer-needed event: url: #{res.issue.url}"
      robot.emit 'review-no-longer-needed',
        url: res.issue.url
        repo: res.repository.full_name
        number: res.issue.number

  reviewNoLongerNeeded = (gitHubIssuesResponse) ->
    labelRemoved = res.action == 'unlabeled' && res.label.name == process.env.HUBOT_REVIEW_NEEDED_LABEL
    issueClosed = res.action == 'closed' && _.some(res.labels, (label) -> label.name == process.env.HUBOT_REVIEW_NEEDED_LABEL)
    labelRemoved || issueClosed

  robot.respond /(list|show) (active owners|AO's|AOs)/i, (msg) ->
    teams = robot.brain.data['teams']
    if Object.keys(teams).length == 0
      response = "Sorry, I'm not keeping track of any teams or their AOs.\n" +
      "Get started with 'Add <team name> to teams'."
      return msg.send response
    aoStatus = (team) ->
      if team.aoUserId?
        aoName = robot.brain.userForId(team.aoUserId).name
        return "#{aoName} has been active owner on #{team.name} for #{moment(team.aoUserAssignedDt).fromNow(true)}"
      else
        "* #{team.name} has no active owner! Use: 'Assign <user> as AO for <team>'."
    aoStatusList = (aoStatus(team) for teamName, team of teams)
    msg.send "AOs:\n" + aoStatusList.join("\n")

  robot.respond /add ([a-z0-9 ]+) to teams/i, (msg) ->
    teamName = msg.match[1]
    if getTeam(teamName)
      return msg.send "#{teamName} already being tracked."
    addTeam(teamName)
    msg.send "#{teamName} added."

  robot.respond /(delete|remove) ([a-z0-9 ]+) from teams/i, (msg) ->
    teamName = msg.match[2]
    if getTeam(teamName)
      removeTeam(teamName)
      return msg.send "Removed #{teamName} from tracked teams."
    msg.send "I wasn't tracking #{teamName}."

  robot.respond /assign ([a-z0-9 -]+) as AO for ([a-z0-9 ]+)/i, (msg) ->
    userId = robot.brain.userForName(msg.match[1])?.id
    teamName = msg.match[2]
    assignTeam userId, teamName, msg
  
  robot.respond /I'm AO for ([a-z0-9 ]+)/i, (msg) ->
    teamName = msg.match[1]
    assignTeam msg.message.user.id, teamName, msg

  assignTeam  = (userId, teamName, msg) ->
    team = getTeam(teamName)
    return msg.send "Never heard of that team. You can add a team with 'Add <team name> to teams'." unless team
    return msg.send "I have no idea who you're talking about." unless userId
    team.assignAo(userId)
    msg.send 'Got it.'

  getTeam = (name) ->
    return robot.brain.data.teams[name.toLowerCase()]
  
  removeTeam = (name) ->
    delete robot.brain.data.teams[name.toLowerCase()]

  addTeam = (name) ->
    robot.brain.data.teams[name.toLowerCase()] = new Team(name)
  
  messageAOs = (message) ->
    messageAO(team, message) for teamName, team of robot.brain.data.teams

  messageAO = (team, message) ->
    if team.aoUserId
      aoUser = robot.brain.userForId(team.aoUserId)
      robot.send(aoUser, message)

class PullRequest
  constructor: (pr) ->
    @repo = pr.repo
    @url = pr.url
    @number = pr.number
    @reviewNeededDt = new Date()
    
class Team
  constructor: (name) ->
    @name = name
    @members = []
    @aoUserId = undefined
    @aoUserAssignedDt = undefined

  assignAo: (userId) ->
    @aoUserId = userId
    @aoUserAssignedDt = new Date()
