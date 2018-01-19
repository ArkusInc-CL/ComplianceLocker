global with sharing class ChatterCompilance_FeedCommentBatch_Log implements Database.Batchable<Sobject>{


    global ChatterCompilance_FeedCommentBatch_Log(){
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
        ArkusChatterComplianceSettings__c Setting = ArkusChatterComplianceSettings__c.getInstance('settings');
        Setting.BatchApexId_Log__c = BC.getJobId();
        Setting.ScheduleJobId_Log__c = NULL;
        update setting;
        return Database.getQueryLocator('SELECT Id, RelatedRecordId, FeedItemId, InsertedById, CommentBody, ParentId From FeedComment ORDER BY createddate ASC');
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope){

        Map<Id, FeedComment> mapFeedComment = new Map<Id, FeedComment>((List<FeedComment>)scope);
        List<String> IdStrings = new List<String>();
        string sId;
        for(FeedComment fc : mapFeedComment.values()){
            sId = fc.Id;
            if(sId.length() == 18){
                IdStrings.add(sId);
                IdStrings.add(sId.substring(0, 16));
            }
        }

        List<ChatterComplianceComment__c> listCCC = [SELECT Id, commentId_New__c FROM ChatterComplianceComment__c WHERE commentId_New__c IN: IdStrings];

        List<ChatterComplianceCommentNew__c> listCCCNew = [SELECT Id, commentId__c FROM ChatterComplianceCommentNew__c WHERE commentId__c IN: IdStrings];

        if(listCCC.Size() >0 || listCCCNew.Size() >0){
            //remove already copied FeedComments
            Set<Id> IdSet = new Set<Id>();
            for(ChatterComplianceComment__c ccc: listCCC){
                IdSet.add(ccc.commentId_New__c);
            }

            for(ChatterComplianceCommentNew__c cccn: listCCCNew){
                IdSet.add(cccn.commentId__c);
            }

            for(Id i: mapFeedComment.KeySet()){
                if(IdSet.contains(i)){
                    mapFeedComment.remove(i);
                }
            }
        }
        if (mapFeedComment.values().size() > 0){
            //ChatterCompliance_Utils.CreateFeedCommentCompliance(mapFeedComment.values(), false);
            ChatterCompliance_Utils.CreateFeedCommentComplianceNew(mapFeedComment.values(), false);
        }
    }


    global void finish(Database.BatchableContext BC){
        DateTime sysTime = system.now().addSeconds(20);
        ArkusChatterComplianceSettings__c Setting = ArkusChatterComplianceSettings__c.getInstance('settings');
        Setting.ScheduleJobId_Log__c = system.schedule('Arkus Compliance for Chatter [FeedItem delete LOG]', sysTime.second() + ' ' + sysTime.minute() + ' ' + sysTime.hour() + ' ' + sysTime.day() + ' ' + sysTime.month() + ' ? ' + sysTime.year() , new ChatterCompilance_ScheduleBatch(1));
        update setting;
    }
}