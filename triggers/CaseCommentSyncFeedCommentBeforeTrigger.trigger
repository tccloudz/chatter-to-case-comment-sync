trigger CaseCommentSyncFeedCommentBeforeTrigger on FeedComment (before insert) {
	CaseFeedCommentSyncUtils.caseFeedCommentToCaseComment(trigger.new);
}