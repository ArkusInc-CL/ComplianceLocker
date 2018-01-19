global with sharing class ChatterComp_FeedCommentDeleteBatch_Log  implements Database.Batchable<Sobject>, Database.Stateful {

    private string objName;
    private string fieldName;

    global ChatterComp_FeedCommentDeleteBatch_Log(string obj){
        this.objName = obj;
        if(obj == 'ChatterComplianceComment__c'){
            fieldName = 'commentId_New__c';
        }
        else{
            fieldName = 'commentId__c';
        }
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
        SObjectType objType = Schema.getGlobalDescribe().get(objName);
        DescribeSObjectResult objDef = objType.getDescribe();
        Map<String, SObjectField> fields = objDef.fields.getMap();
        if(fields.containsKey(fieldName)){}
            return Database.getQueryLocator('SELECT Id, ' + fieldName + ' From ' + objName + ' WHERE deleted__c = false');
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope){
        if(objName == 'ChatterComplianceComment__c'){
            List<ChatterComplianceComment__c> listCC = (List<ChatterComplianceComment__c>)scope;

            Set<Id> setCCId = new Set<Id>();
            for(ChatterComplianceComment__c cc: ListCC){
                setCCId.add(cc.commentId_New__c);
            }

            //all feedItems in scope
            List<FeedComment> listItems = [SELECT Id FROM FeedComment WHERE Id IN: setCCId];

            Set<Id> setItemsId = new Set<Id>();
            for(FeedComment item: listItems){
                setItemsId.add(item.Id);
            }

            //remove chatter compilances that dont have a FeedItem
            for(Id cc : setCCId){
                if(setItemsId.Contains(cc)){
                    setCCId.remove(cc);
                }
            }

            List<Id> result = new List<Id>(setCCId);
            if(result.size() > 0){
                ChatterCompliance_Utils.DeleteFeedCommentCompliance(null, result, false);
            }
        }
        else{
            List<ChatterComplianceCommentNew__c> listCC = (List<ChatterComplianceCommentNew__c>)scope;

            Set<Id> setCCId = new Set<Id>();
            for(ChatterComplianceCommentNew__c cc: ListCC){
                setCCId.add(cc.commentId__c);
            }

            //all feedItems in scope
            List<FeedComment> listItems = [SELECT Id FROM FeedComment WHERE Id IN: setCCId];

            Set<Id> setItemsId = new Set<Id>();
            for(FeedComment item: listItems){
                setItemsId.add(item.Id);
            }

            //remove chatter compilances that dont have a FeedItem
            for(Id cc : setCCId){
                if(setItemsId.Contains(cc)){
                    setCCId.remove(cc);
                }
            }

            List<Id> result = new List<Id>(setCCId);
            if(result.size() > 0){
                ChatterCompliance_Utils.DeleteFeedCommentCompliance(null, result, false);
            }
        }

    }


    global void finish(Database.BatchableContext BC){
        ArkusChatterComplianceSettings__c Setting = ArkusChatterComplianceSettings__c.getInstance('settings');
        if(objName != 'ChatterComplianceComment__c'){
            Setting.BatchApexId_Log__c = NULL;
            Setting.ScheduleJobId_Log__c = NULL;
        }
        else{
            DateTime sysTime = system.now().addSeconds(20);
            Setting.ScheduleJobId_Log__c = system.schedule('Arkus Compliance for Chatter [FeedComment NEW delete LOG]', sysTime.second() + ' ' + sysTime.minute() + ' ' + sysTime.hour() + ' ' + sysTime.day() + ' ' + sysTime.month() + ' ? ' + sysTime.year() , new ChatterCompilance_ScheduleBatch(3));
        }
        update setting;
    }
}