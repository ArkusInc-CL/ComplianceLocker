/**
*   Chatter Compliance System (all classes, triggers and pages that start with ChatterCompliance)
*   @author     Arkus Dev Team
*/
trigger ChatterCompliance_CCCBeforeDelete on ChatterComplianceComment__c bulk (before delete) {

    if(trigger.isDelete){
        Set<Id> postContentIds = new Set<Id>();
        for(ChatterComplianceComment__c ccc : trigger.old){
            if(ccc.Chatter_Compliance_Post_Content_Info__c != null){
                postContentIds.add(ccc.Chatter_Compliance_Post_Content_Info__c);
            }
        }
        delete [SELECT Id FROM ChatterCompliance_PostContentInformation__c WHERE Id IN :postContentIds];

    }

}