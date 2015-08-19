# Description
#   Message Team Leads when a attention-everyone is added to a PR
TeamLeadsHelper = require '../TeamLeadsHelper
'
module.exports = (robot) ->

  teamLeadsHelper = new TeamLeadsHelper robot
  
  robot.on 'attention-everyone', (attentionEveryone) ->
    message = "The attention-everyone label was added to " +
    "PR(#{attentionEveryone.number}) #{attentionEveryone.url}\n" +
    "All Team Leads need to review this Pull Request"
    teamLeadsHelper.messageTeamLeads(message)
