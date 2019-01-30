/**
	@author Terence Chiu
	@date 6/20/2015
	@param COMMENTINSERT Used to indicate feed item to case comment action
	@param FEEDREMOVAL Used to indicate removal of a duplicate feed item action
	@description This class handles all logic for syncing Feed Items and Feed Comments from a Case record feed
				 to a Case Comment;
*/
global class CaseFeedCommentSyncUtils {

    global static String COMMENTINSERT = 'FeedItem2Case';
    global static String FEEDREMOVAL = 'CaseCommentFeedItemDeletion';
    final static String FROMCHATTER = 'Case Comment from Feed';
    
    /**
		@description The class contains Invocable variables to used as sync parameters in conjuction with process builder.
	*/
    global class SyncParameter{
        @InvocableVariable(Label = 'Sync Type'
                          Description = 'Indicates Feed sync or feed item removal'
                           Required = true)
       	global String syncType;
        
        @InvocableVariable(Label = 'Feed Body'
                          Description = 'Body of the chatter post')
       	global String feedBody;
        
        @InvocableVariable( Label = 'CreatedById'
                            Description = 'Record Id of the User that created the new record')
        global String createdById;
        
         @InvocableVariable(Label = 'Parent Id'
                          Description = 'Id of parent record, feed item or case comment'
                           Required = true)
       	global String parentId;
            
    }
    
    /**
     	@param syncParam List of type SyncParameter. 
		@description This method takes a list of type SyncParameter and determines the correct action that needs
					 to be taken based on SyncParameter.syncType. CaseComment records will be inserted or 
					 duplicate feed items will be removed.
	*/
    @InvocableMethod
    global static void chatterFeedToCaseComment(List<SyncParameter> syncParams){
        //if syncType if Case Comment insertion, create case comment object
        if(syncParams[0].syncType == COMMENTINSERT){
            String feedBody = syncParams[0].feedBody;
            String parentId = syncParams[0].parentId;
            CaseComment cc = feedBody != null && parentId != null ? 
                new CaseComment(CommentBody = feedBody + + '\n\n ' + FROMCHATTER, ParentId = parentId) : null;
            
            if(cc != null){
                try{
                    insert cc;
                }catch(Exception caseCommentInsEx){
                    system.debug(LoggingLevel.ERROR, 'Case Comment Insert Error: ' + caseCommentInsEx.getMessage());
                }
            }
        }
        //if syncType is duplicate feed item removal find all duplicate feed items from case feed and delete
        else if(syncParams[0].syncType == FEEDREMOVAL){
            List<Id> delFeedIds = new List<Id>();
        	ConnectApi.FeedElementPage feedPage = 
            Connectapi.ChatterFeeds.getFeedElementsFromFeed(null, ConnectApi.feedtype.Record, syncParams[0].parentId);
            
            system.debug(LoggingLevel.ERROR, 'Feed Page for Case: ' + feedPage);
            
            if(feedPage != null){
        		for(ConnectApi.FeedElement elem : feedPage.elements){
            		if(elem.capabilities != null){
                		if(elem.capabilities.caseComment != null){
                    		String caseCommentTxt = elem.capabilities.caseComment.text != null ? elem.capabilities.caseComment.text : '';
                    
                    		if(caseCommentTxt.contains(FROMCHATTER)){
                        		String currPageUrl = elem.capabilities.chatterLikes.page.currentPageUrl;
                        		List<String> urlSplit = currPageUrl.split('/');
                        		delFeedIds.add(urlSplit[6]);
                    		}                    
                		}
            		}
        		}
        
        	try{
            	List<database.DeleteResult> delRes = !delFeedIds.isEmpty() ? Database.delete(delFeedIds) : null;
        	}catch(DMLException feedDelEx){
            	system.debug(LoggingLevel.ERROR, 'error during feed item deletion: ' + feedDelEx.getMessage());
        	}
          }
        }
    }
    
    /**
		@param feedComments A list of type Feed Comments
		@description This method takes a list of feed comments and creates a corresponding case comment if the
					 feed comment is part of a case feed.s
	*/
    global static void caseFeedCommentToCaseComment(List<FeedComment> feedComments){
    	List<CaseComment> caseComments = new List<CaseComment>();    
        	for(FeedComment feedCom : feedComments){        
        		String parentId = (String)feedCom.ParentId;
        
        		if(parentId.startsWith('500')){
      				CaseComment cc = new CaseComment(ParentId = feedCom.ParentId, CommentBody = 
                                                 feedCom.CommentBody + '\n\n' + FROMCHATTER);
         		caseComments.add(cc);	
        		}
    		}
    
    		try{
      			List<Database.SaveResult> insRes = !caseComments.isEmpty() ? Database.insert(caseComments) : null;  
    		}catch(DMLException commentInsEx){
        		system.debug('Error during case comment insertion: ' + commentInsEx.getMessage());
    		}     
    }
    
}