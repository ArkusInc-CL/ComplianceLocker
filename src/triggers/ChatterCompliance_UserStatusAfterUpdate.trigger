/**
*   Chatter Compliance System (all classes, triggers and pages that start with ChatterCompliance)
*   @author     Arkus Dev Team
*/
trigger ChatterCompliance_UserStatusAfterUpdate on User bulk (after update, before update) {
    if(trigger.isBefore){
        ArkusChatterComplianceSettings__c chatter = ArkusChatterComplianceSettings__c.getInstance('settings');
        if(chatter != null){
            if(!chatter.Chatter_Compliance_paused__c){         
                if(!ChatterCompliance_AdminSettings.existId(chatter.ChatterCompliance_Owner__c)){
                    for(User u : trigger.new){
                        //if(trigger.oldMap.get(u.Id).CurrentStatus != u.CurrentStatus && u.CurrentStatus != null && u.CurrentStatus != ''){
                        u.addError(ChatterCompliance_AdminSettings.msgCurrentOwnerDoesNotExists);
                        //}
                    }
                }
                if(chatter.ChatterCompliance_Owner__c != null){
                    for(User u : trigger.new){
                        Id theCCUserId = chatter.ChatterCompliance_Owner__c;
                        if(u.isActive == false && u.Id == theCCUserId){  
                            u.addError(ChatterCompliance_AdminSettings.msgCanNotDeactivateUser);    
                            u.isActive.addError(ChatterCompliance_AdminSettings.msgCanNotDeactivateUser);
                        }
                    }
                }
            }
        }
    }
    /***********************************************************/    
    /**
    *   Creates/updates a chatterCompliance record when a user updates his user status.
    */
    /*if(trigger.isAfter){
        
        List<ChatterCompliance__c> toUpdate = new List<ChatterCompliance__c>();
        
        if(ArkusChatterComplianceSettings__c.getInstance('settings') != null){
            if(!ArkusChatterComplianceSettings__c.getInstance('settings').Chatter_Compliance_paused__c){
            
                ArkusChatterComplianceSettings__c chatter = ArkusChatterComplianceSettings__c.getInstance('settings');
            
                ChatterCompliance_AdminSettings.refreshOldCCRecords();
            
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
                                        From UserFeed u where (parentId in : tempList) order by createddate desc limit 9500]){
                    //uf.add(item);
                    if(map_User_UserFeed.get(item.parentId) == null){
                        map_User_UserFeed.put(item.parentId,item);
                    }
                }
                
                if(trigger.isUpdate){
                    for(integer i = 0; i < trigger.new.size(); i++){
                        User oldUser = trigger.old[i];//trigger.old[0];
                        User newUser = trigger.new[i];//trigger.new[0]; 
                        if(newUser.IsActive){
                            if(newUser.CurrentStatus != null && newUser.CurrentStatus != ''){
                                UserFeed feedAux = map_User_UserFeed.get(newUser.id);
                                if(feedAux != null){
                                    UserFeed feed = feedAux;//uf.get(i);
                                    ChatterCompliance__c cc = new ChatterCompliance__c();
                                    
                                    Id id1 = newUser.Id;
                                    if(ChatterCompliance_AdminSettings.static_global_map3 != null){
                                        if(ChatterCompliance_AdminSettings.static_global_map3.get(id1 + '~') != null){
                                            cc.PostContentInformation__c = ChatterCompliance_AdminSettings.static_global_map3.get(id1 + '~');
                                        }
                                        if(ChatterCompliance_AdminSettings.static_global_map3.get(id1 + '~' + '1') != null){
                                            cc.OriginalPostContent__c = ChatterCompliance_AdminSettings.static_global_map3.get(id1 + '~' + '1');
                                        }
                                    }
                                                
                                    
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
                    }
                    
                    ChatterCompliance_AdminSettings.sendEmails(toUpdate);
                    
                    if(!chatter.Do_NOT_create_the_chatter_compliance_rec__c){
                        insert toUpdate;
                    }
                }
            }
        }
    
    }*/
    
}