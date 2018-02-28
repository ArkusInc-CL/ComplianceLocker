/**
*   Chatter Compliance System (all classes, triggers and pages that start with ChatterCompliance)
*   @author     Arkus Dev Team
*/
trigger ChatterCompliance_FeedCommentAfterInsertDelete_v1_2 on FeedComment bulk (after delete, after insert) {
    
    /**
    *   Creates/updates a chatterComplianceComment record when a chatter comment is created/deleted.
    */
        
    if(ArkusChatterComplianceSettings__c.getInstance('settings') != null){
        if(!ArkusChatterComplianceSettings__c.getInstance('settings').Chatter_Compliance_paused__c){
            
            if(Schema.sObjectType.ChatterComplianceComment__c.isUpdateable()){
                // For non chatter free users
                List<ChatterComplianceComment__c> toUpdate = new List<ChatterComplianceComment__c>();
                     
                Map<Id,ChatterCompliance__c> ccs = new Map<Id,ChatterCompliance__c>();
                Map<Id,ChatterComplianceComment__c> comments = new Map<Id,ChatterComplianceComment__c>();
                List<Id> tempList = new List<Id>();
                
                if(trigger.isInsert){
                    for(FeedComment f : trigger.new){
                        tempList.add(f.FeedItemId);
                    }
                }else if(trigger.isDelete){
                    for(FeedComment f : trigger.old){
                        tempList.add(f.id);
                    }
                }
                
                for(ChatterCompliance__c cc : [Select id,PostId_New__c,Related_record_name__c,PostContent__c from ChatterCompliance__c where PostId_New__c in : tempList]){
                    ccs.put(cc.PostId_New__c,cc);
                }
                
                for(ChatterComplianceComment__c ccc : [Select id,commentId_New__c from ChatterComplianceComment__c where commentId_New__c in : tempList]){
                    comments.put(ccc.commentId_New__c,ccc);
                }
                    
                if(trigger.isInsert){
                    for(FeedComment f : trigger.new){
                        ChatterCompliance__c relatedCompliance = ccs.get(f.feedItemId);
                        if(relatedCompliance != null){
                            ChatterComplianceComment__c cc = new ChatterComplianceComment__c();
                            cc.ChatterCompliance__c = relatedCompliance.id;
                            cc.commentContent__c = f.CommentBody;
                            cc.commentId_New__c = f.id; 
                            toUpdate.add(cc);
                        }
                    }
                    insert toUpdate;
                    ChatterCompliance_AdminSettings.sendEmails(toUpdate);
                }
                
                if(trigger.isDelete){
                    for(FeedComment f : trigger.old){
                        ChatterComplianceComment__c item = comments.get(f.id);
                        if(item != null){
                            item.deleted__c = true;
                            item.deleted_Date__c = Datetime.now();
                            item.deletedBy__c = Userinfo.getUserId();
                            toUpdate.add(item);
                        }
                    }
                    upsert toUpdate;
                }
            }else{
                
                // For Chatter Free Users
                List<ChatterComplianceCommentNew__c> toUpdate = new List<ChatterComplianceCommentNew__c>();
                     
                Map<Id,ChatterCompliance__c> ccs = new Map<Id,ChatterCompliance__c>();
                Map<Id,ChatterComplianceCommentNew__c> comments = new Map<Id,ChatterComplianceCommentNew__c>();
                List<Id> tempList = new List<Id>();
                
                if(ArkusChatterComplianceSettings__c.getInstance('settings') != null){
                            
                    String owner = ArkusChatterComplianceSettings__c.getInstance('settings').ChatterCompliance_owner__c;
                    
                    if(trigger.isInsert){
                        for(FeedComment f : trigger.new){
                            tempList.add(f.FeedItemId);
                        }
                    }else if(trigger.isDelete){
                        for(FeedComment f : trigger.old){
                            tempList.add(f.id);
                        }
                    }
                    
                    for(ChatterCompliance__c cc : [Select id,PostId_New__c,Related_record_name__c,PostContent__c from ChatterCompliance__c where PostId_New__c in : tempList]){
                        ccs.put(cc.PostId_New__c,cc);
                    }
                    
                    for(ChatterComplianceCommentNew__c ccc : [Select id,commentId__c from ChatterComplianceCommentNew__c where commentId__c in : tempList]){
                        comments.put(ccc.commentId__c,ccc);
                    }
                        
                    if(trigger.isInsert){
                        for(FeedComment f : trigger.new){
                            ChatterCompliance__c relatedCompliance = ccs.get(f.feedItemId);
                            if(relatedCompliance != null){
                                ChatterComplianceCommentNew__c cc = new ChatterComplianceCommentNew__c();
                                cc.ChatterCompliance__c = relatedCompliance.id;
                                cc.commentContent__c = f.CommentBody;
                                cc.commentId__c = f.id; 
                                cc.OwnerId = owner; 
                                toUpdate.add(cc);
                            }
                        }
                        insert toUpdate;
                        ChatterCompliance_AdminSettings.sendEmails(toUpdate);
                    }
                    
                    if(trigger.isDelete){
                        for(FeedComment f : trigger.old){
                            ChatterComplianceCommentNew__c item = comments.get(f.id);
                            if(item != null){
                                item.deleted__c = true;
                                item.deleted_Date__c = Datetime.now();
                                item.deletedBy__c = Userinfo.getUserId();
                                toUpdate.add(item);
                            }
                        }
                        upsert toUpdate;
                    }
                }
            }
        }
    }
}