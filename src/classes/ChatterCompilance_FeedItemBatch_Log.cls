global with sharing class ChatterCompilance_FeedItemBatch_Log implements Database.Batchable<Sobject>{

    global ChatterCompilance_FeedItemBatch_Log(){
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
        //, body, contentdata, likecount, contentsize, contentdescription, linkurl, contentfilename, parentid, ocreateddate, contenttype, type, createdbyid, lastmodifieddate, insertedbyid, id, title, commentcount, relatedrecordid, isdeleted, systemmodstamp
        return Database.getQueryLocator('SELECT Id, body, likecount, contentsize, contentdescription, linkurl, contentfilename, parentid, createddate, contenttype, type, createdbyid, lastmodifieddate, insertedbyid, title, commentcount, relatedrecordid, isdeleted, systemmodstamp FROM FeedItem ORDER BY createddate ASC');
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope){
        Map<Id, FeedItem> items = new Map<Id, FeedItem>((List<FeedItem>)scope);
        List<String> IdStrings = new List<String>();
        string sId;
        for(FeedItem fi : items.values()){
            sId = fi.Id;
            if(sId.length() == 18){
                IdStrings.add(sId);
                IdStrings.add(sId.substring(0, 16));
            }
        }
        list<ChatterCompliance__c> ccList = [SELECT Id, PostId_New__c FROM ChatterCompliance__c Where PostId_New__c IN :IdStrings];
        if(ccList.Size() >0){
            //remove already copied FeedItems
            Set<Id> IdSet = new Set<Id>();
            for(ChatterCompliance__c cc: ccList){
                IdSet.add(cc.PostId_New__c);
            }

            for(Id i: items.KeySet()){
                if(IdSet.contains(i)){
                    items.remove(i);
                }
            }
        }
        if (items.values().size() > 0){
               ChatterCompliance_Utils.CreateFeedItemCompliance(items.values(), false);
        }
    }


    global void finish(Database.BatchableContext BC){
        DateTime sysTime = system.now().addSeconds(20);
        ArkusChatterComplianceSettings__c Setting = ArkusChatterComplianceSettings__c.getInstance('settings');
        Setting.ScheduleJobId_Log__c = system.schedule('Arkus Compliance for Chatter [FeedComment LOG]', sysTime.second() + ' ' + sysTime.minute() + ' ' + sysTime.hour() + ' ' + sysTime.day() + ' ' + sysTime.month() + ' ? ' + sysTime.year() , new ChatterCompilance_ScheduleBatch(0));
        update setting;
    }
}