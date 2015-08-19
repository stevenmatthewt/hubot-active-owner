# Description
#   Let Hubot keep track of who is the Team Lead for each team
#
# Commands:
#   hubot show Team Leads - show a list of all team leads
#   hubot assign <user> as team lead of <team> - assign a team lead to a team
#   hubot remove Team Lead of <team> - remove the team lead of a team
#   hubot remove <user> from team leads - remove all Team Lead roles from a user
TeamLeadsHelper = require '../TeamLeadsHelper'
ActiveOwnerHelper = require '../ActiveOwnerHelper'

module.exports = (robot) ->
  teamLeadsHelper = new TeamLeadsHelper robot
  activeOwnerHelper = new ActiveOwnerHelper robot

  robot.brain.data.teamLeads ||= {}
  robot.brain.data.attentionEveryones ||= {}

  robot.respond /(show|list) (team leads|team leaders)/i, (msg) ->
    teamLeads = robot.brain.data.teamLeads
    if Object.keys(teamLeads).length == 0
      return msg.send "There are currently no Team Leads being tracked at the moment.\n" +
      "You can add a Team Lead with 'Add <user> as Team Lead of <team>'"
    teamLeadDescription = (teamLead) ->
      teamLeadName = robot.brain.userForId(teamLead.id).name
      "#{teamLeadName} is Lead of #{teamLead.teamName}"
    teamLeadDescriptions = (teamLeadDescription(teamLeads[prop]) for prop of teamLeads)
    msg.send "Team Leads:\n" + teamLeadDescriptions.join("\n") + "\nUse: add <user> as Team Lead of <team>"

  robot.respond /(add|assign|set) ([a-z0-9 -@]+) as team lead (of|for|to) ([a-z0-9 ]+)/i, (msg) ->
    teamLead = activeOwnerHelper.getUserForName(msg.match[2])
    if !teamLead?
      return msg.send "There does not appear to be a user with that name..."
    team = msg.match[4]
    oldLead = teamLeadsHelper.addTeamLead teamLead.id, team
    if oldLead?
      oldLeadName = robot.brain.userForId(oldLead.id).name
      return msg.send "#{teamLead.name} has successfully replaced #{oldLeadName} as Team Lead of #{team}"
    msg.send "#{teamLead.name} successfully set as Team Lead of #{team}"

  robot.respond /(remove|delete) (Team Lead|Team Leads) (for|of) ([a-z0-9 ]+)/i, (msg) ->
    team = msg.match[4]
    teamLead = robot.brain.data.teamLeads[team]
    if !teamLead?
      return msg.send "That Team does not have a Team Leader!"
    teamLeadName = robot.brain.userForId(teamLead.id).name
    if teamLeadsHelper.deleteTeamLead team
      return msg.send "#{teamLeadName} successfully removed from Team Leads"
    msg.send "#{teamLeadName} is not a Team Lead!"

  robot.respond /(delete|remove) ([a-z0-9 -@]+) (from Team Leads|as Team Lead)/i, (msg) ->
    teamLead = activeOwnerHelper.getUserForName(msg.match[2])
    if !teamLead?
      return msg.send "There is no user with that name!"
    deleted = teamLeadsHelper.deleteUserFromTeamLeads teamLead.id
    if !deleted? or deleted.length == 0
      return msg.send "That user is not a Team Lead"
    deletedNames = deleted.map (teamLead) ->
      teamLead.teamName
    msg.send "Successfully removed #{teamLead.name} from these teams:\n\t" + 
    deletedNames.join("\n\t")
    


