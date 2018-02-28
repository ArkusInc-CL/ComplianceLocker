/**
*   Chatter Compliance System (all classes, triggers and pages that start with ChatterCompliance)
*   @author     Arkus Dev Team
*/
trigger ChatterCompliance_CCCNewBeforeDelete on ChatterComplianceCommentNew__c (before delete) {

    if(trigger.isDelete){
        Set<Id> postContentIds = new Set<Id>();
        for(ChatterComplianceCommentNew__c cccNew : trigger.old){
            if(cccNew.Chatter_Compliance_Post_Content_Info__c != null){
                postContentIds.add(cccNew.Chatter_Compliance_Post_Content_Info__c);
            }
        }
        delete [SELECT Id FROM ChatterCompliance_PostContentInformation__c WHERE Id IN :postContentIds];

    }

}