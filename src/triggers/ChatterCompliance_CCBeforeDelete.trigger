/**
*   Chatter Compliance System (all classes, triggers and pages that start with ChatterCompliance)
*   @author     Arkus Dev Team
*/
trigger ChatterCompliance_CCBeforeDelete on ChatterCompliance__c bulk (before delete) {

    if(trigger.isDelete){
        Set<Id> postContentIds = new Set<Id>();
        for(ChatterCompliance__c cc : trigger.old){
            if(cc.PostContentInformation__c != null){
                postContentIds.add(cc.PostContentInformation__c);
            }
        }
        // Get Post Content info records related to comments:
        for(ChatterCompliance__c cc : [SELECT (SELECT Chatter_Compliance_Post_Content_Info__c FROM ChatterComplianceComments__r WHERE Chatter_Compliance_Post_Content_Info__c != null) FROM ChatterCompliance__c WHERE Id IN :trigger.oldMap.keySet()]){
            for(ChatterComplianceComment__c ccc : cc.ChatterComplianceComments__r){
                postContentIds.add(ccc.Chatter_Compliance_Post_Content_Info__c);
            }
        }
        // --------
        
        delete [SELECT Id FROM ChatterCompliance_PostContentInformation__c WHERE Id IN :postContentIds];
        delete [SELECT Id FROM ChatterComplianceCommentNew__c WHERE ChatterCompliance__c IN: trigger.oldMap.keySet()];

    }
    
}