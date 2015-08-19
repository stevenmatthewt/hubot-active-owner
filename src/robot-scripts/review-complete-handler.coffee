# Description
#   Message AOs and remove PRs from review list on review-complete events
AOHelper = require '../ActiveOwnerHelper'

module.exports = (robot) ->

  helper = new AOHelper robot

  robot.on 'potential-review-complete', (review) ->
  	if helper.getReview review.key
	    helper.removeReview(review.key)
	    message = "Review no longer needed for #{review.url}. The PR either was closed or review label was removed."
	    helper.messageAOs message
