/**
*   Chatter Compliance System (all classes, triggers and pages that start with ChatterCompliance)
*   @author     Arkus Dev Team
*/
trigger ChatterCompliance_UserStatusAfterUpdate_v1_2 on User bulk (after update) {
    
    /**
    *   Creates/updates a chatterCompliance record when a user updates his user status.
    */
    
    //if(Schema.sObjectType.ChatterCompliance__c.isCreateable()){
        List<ChatterCompliance__c> toUpdate = new List<ChatterCompliance__c>();
        
        if(ArkusChatterComplianceSettings__c.getInstance('settings') != null){
            if(!ArkusChatterComplianceSettings__c.getInstance('settings').Chatter_Compliance_paused__c){
            
                String owner = ArkusChatterComplianceSettings__c.getInstance('settings').ChatterCompliance_Owner__c;
                
                //List<UserFeed> uf = new List<UserFeed>();
                List<Id> tempList = new List<Id>();
                if(trigger.isUpdate){
                    for(User f : trigger.new){
                        tempList.add(f.id);
                    }
                }
                
                Map<Id, UserFeed> map_User_UserFeed = new Map<Id, UserFeed>(); 
                for(UserFeed item : [   Select u.Body, ParentId, u.RelatedRecordId 
                                        From UserFeed u where (parentId in : tempList) order by createddate desc]){
                    //uf.add(item);
                    if(map_User_UserFeed.get(item.parentId) == null){
                        map_User_UserFeed.put(item.parentId,item);
                    }
                }
                
                if(trigger.isUpdate){
                    for(integer i = 0; i < trigger.new.size(); i++){
                        User oldUser = trigger.old[i];//trigger.old[0];
                        User newUser = trigger.new[i];//trigger.new[0]; 
                        if(oldUser.CurrentStatus != newUser.CurrentStatus && newUser.CurrentStatus != null && newUser.CurrentStatus != ''){
                            UserFeed feedAux = map_User_UserFeed.get(newUser.id);
                            if(feedAux != null){
                                UserFeed feed = feedAux;//uf.get(i);
                                ChatterCompliance__c cc = new ChatterCompliance__c();
                                if(owner != null && owner != '') cc.OwnerId = owner;
                                cc.delete__c = false;
                                cc.update__c = false;
                                cc.PostId_New__c = feed.id;
                                cc.Post_Created_Date__c = Datetime.now();
                                cc.update__c = false;
                                cc.user__c = newUser.id;
                                cc.Related_record__c = newUser.id;
                                cc.Related_record_name__c = newUser.FirstName + ' ' + newUser.LastName;
                                cc.PostContent__c = feed.Body;
                                toUpdate.add(cc);
                            }
                        }
                    }
                    
                    ChatterCompliance_AdminSettings.sendEmails(toUpdate);
                    
                    insert toUpdate;
                }
            }
        }
        
    //}
    

}