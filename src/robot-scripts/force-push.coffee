# Description
#   Message AOs about master or a release branch being force pushed too.
AOHelper = require '../ActiveOwnerHelper'

module.exports = (robot) ->

  helper = new AOHelper robot

  robot.on 'force-push', (push) ->
    message = "#{push.branch} has been forced push by #{push.user} onto #{push.repo}. Last commit hash before the push was #{push.shaBefore}." 
    helper.messageAOs message
