@isTest
private class TestCaseCommentSyncUtils {
    
    final static String COMMENTINSERT = 'FeedItem2Case';
    final static String FEEDREMOVAL = 'CaseCommentFeedItemDeletion';
    
    static testMethod void testChatterFeedToCaseComment(){
        CaseFeedCommentSyncUtils.SyncParameter createSP = new CaseFeedCommentSyncUtils.SyncParameter();
        Case testCase = new Case(Subject = 'Chatter Sync Test Case');
        List<CaseFeedCommentSyncUtils.SyncParameter> syncParams 
                        = new List<CaseFeedCommentSyncUtils.SyncParameter>();
                    
        try{
            insert testCase;
        }catch(DMLException testCaseInsEx){
            system.debug('Error during test case insertion: ' + testCaseInsEx.getMessage());
        }
        
        if(testCase.Id != null){
            List<FeedItem> feedItems = new List<FeedItem>();
            Boolean fiInsSuccess = true;
            for(Integer i = 0; i < 40; i++){
                FeedItem fi = new FeedItem(ParentId = testCase.Id, Body = 'Testing Sync to Case Comment');
                feedItems.add(fi);
            }
            test.startTest();
                    
               
            try{
				insert feedItems;                
            }catch(DMLException feedItemInsEx){
                system.debug(LoggingLevel.ERROR, 'Error during feed item insertion: ' + feedItemInsEx.getMessage());
            	fiInsSuccess = false;
            }
            
            if(fiInsSuccess){
                for(Integer j = 0; j < 20; j++){
                    createSP.syncType = CaseFeedCommentSyncUtils.COMMENTINSERT;
                    createSP.parentId = feedItems[j].ParentId;
                    createSP.feedBody = feedItems[j].Body;
                    syncParams.add(createSP);
                    CaseFeedCommentSyncUtils.chatterFeedToCaseComment(syncParams);
                }
                    
                
                for(Integer k = 20; k < feedItems.size(); k++){
                    createSP.syncType = CaseFeedCommentSyncUtils.FEEDREMOVAL;
					syncParams.clear();
                    syncParams.add(createSP);
                    ConnectApi.FeedElementPage fep = new ConnectApi.FeedElementPage();
                    fep.elements = new List<ConnectApi.FeedElement>();
                    ConnectApi.feeditem feedElem = new ConnectApi.feeditem();
                    feedElem.capabilities = new ConnectApi.FeedElementCapabilities();
                    feedElem.capabilities.caseComment = new ConnectApi.CaseCommentCapability();
                    feedElem.capabilities.caseComment.text = 'Case Comment from Feed';
                    feedElem.capabilities.chatterLikes = new ConnectApi.ChatterLikesCapability();
                    feedElem.capabilities.chatterLikes.page = new ConnectApi.ChatterLikePage();
                    feedElem.capabilities.chatterlikes.page.currentPageUrl = 'a/b/c/d/e/g/' + feedItems[k].Id + '/h';
                    fep.elements.add(feedElem);
                    ConnectApi.ChatterFeeds.setTestGetFeedElementsFromFeed(null, ConnectApi.feedtype.Record, testCase.Id, fep);
                    CaseFeedCommentSyncUtils.chatterFeedToCaseComment(syncParams);
                } 
            }
                
                
                
                
             
            
            test.stopTest(); 
            
            List<CaseComment> caseComments = [SELECT Id FROM CaseComment WHERE ParentId = :testCase.Id];
            List<FeedItem> feedItemRePull = [SELECT Id,ParentId FROM FeedItem WHERE ParentId = :testCase.Id];
            system.debug(feedItemRePull);
            system.assertEquals(feedItems.size() / 2, caseComments.size(), 'There should be the same amount of case comments as feed items inserted');
        	system.assertEquals(feedItems.size() / 2, feedItemRePull.size(), 'Duplicate feed items from case comments should be removed');
        
        	testCaseFeedCommentToCaseComment(feedItemRePull);
        }
        
    }
    
    private static void testCaseFeedCommentToCaseComment(List<FeedItem> feedItems){
    	List<FeedComment> feedComments = new List<FeedComment>();
        for(FeedItem fi : feedItems){
        	FeedComment fc = new FeedComment(FeedItemId = fi.Id, CommentBody = 'TEST FEED COMMENT SYNC');
            feedComments.add(fc);           
        }
        
        
        try{
            insert feedComments;
        }catch(DMLException feedCommInsEx){
            system.debug(LoggingLevel.ERROR, 'Error during feed comment insertion: ' + feedCommInsEx.getMessage());
        }
        
        
        List<CaseComment> caseComments = [SELECT Id FROM CaseComment WHERE Id = :feedItems[0].ParentId];
        
        system.assertNotEquals(feedItems.size() * 2, caseComments.size(), 
                               'The number of case comments should be the total of feed items and feed comments');
    }

}