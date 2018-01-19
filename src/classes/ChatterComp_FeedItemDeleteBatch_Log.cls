global with sharing class ChatterComp_FeedItemDeleteBatch_Log implements Database.Batchable<Sobject>{

    global ChatterComp_FeedItemDeleteBatch_Log(){
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator('SELECT Id, PostId_New__c From ChatterCompliance__c');
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope){
        List<ChatterCompliance__c> listCC = (List<ChatterCompliance__c>)scope;

        Set<Id> setCCId = new Set<Id>();
        for(ChatterCompliance__c cc: ListCC){
            setCCId.add(cc.PostId_New__c);
        }

        //all feedItems in scope
        List<FeedItem> listItems = [SELECT Id FROM FeedItem WHERE Id IN: setCCId];

        Set<Id> setItemsId = new Set<Id>();
        for(FeedItem item: listItems){
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
            ChatterCompliance_Utils.DeleteFeedItemCompliance(NULL, result, false);
        }
    }


    global void finish(Database.BatchableContext BC){
        DateTime sysTime = system.now().addSeconds(20);
        ArkusChatterComplianceSettings__c Setting = ArkusChatterComplianceSettings__c.getInstance('settings');
        Setting.ScheduleJobId_Log__c = system.schedule('Arkus Compliance for Chatter [FeedComment delete LOG]', sysTime.second() + ' ' + sysTime.minute() + ' ' + sysTime.hour() + ' ' + sysTime.day() + ' ' + sysTime.month() + ' ? ' + sysTime.year() , new ChatterCompilance_ScheduleBatch(2));
        update setting;
    }
}