global with sharing class ChatterCompliance_OriginalCheckDeleted implements Schedulable {

    global void execute(SchedulableContext sc) {
        ArkusChatterComplianceSettings__c adminSettings = ArkusChatterComplianceSettings__c.getInstance('settings');
        Integer pastDays = Integer.valueOf(adminSettings.Time_to_delete_original_records__c);
        if(pastDays < 0){pastDays = 0;}
        Date tmpDate = Date.today().addDays(-pastDays);
        delete Database.query('Select Id from FeedItem where createddate <: tmpDate limit 8000');
    }
}