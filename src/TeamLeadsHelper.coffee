TeamLead = require './TeamLead'
_ = require 'lodash'

class TeamLeadsHelper
  constructor: (@robot) ->

  addTeamLead: (teamLeadId, team) ->
    oldTeamLead = @robot.brain.data.teamLeads[team]
    if oldTeamLead?
      oldTeamLead = @robot.brain.userForId oldTeamLead.id
    @robot.brain.data.teamLeads[team] = new TeamLead teamLeadId, team
    return oldTeamLead

  deleteTeamLead: (team) ->
    @robot.logger.debug("Deleting team lead for team: #{team}")
    val = @robot.brain.data.teamLeads[team]
    delete @robot.brain.data.teamLeads[team]
    val

  messageTeamLeads: (message) ->
    @messageTeamLead(teamLead.id, message) for teamName, teamLead of @robot.brain.data.teamLeads

  messageTeamLead: (teamLeadId, message) ->
    teamLead = @robot.brain.userForId(teamLeadId)

    user = _.clone(teamLead)
    delete user['reply_to']
    @robot.logger.debug "Messaging user #{user.id}: " +
      "#{JSON.stringify teamLead}"
    @robot.reply(user, message)

  deleteUserFromTeamLeads: (id) ->
    (@deleteTeamLead team for team, teamLead of @robot.brain.data.teamLeads when teamLead.id is id)

module.exports = TeamLeadsHelper
