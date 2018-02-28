/**
*   Chatter Compliance System (all classes, triggers and pages that start with ChatterCompliance)
*   @author     Arkus Dev Team
*/
trigger ChatterCompliance_FeedCommentAfterInsertDelete_new on FeedComment bulk (after delete, after insert, after update) {
    ArkusChatterComplianceSettings__c adminSettings  = ArkusChatterComplianceSettings__c.getInstance('settings');
 
if (adminSettings.Chatter_Compliance_paused__c==false){
      list<ChatterCompliance_PostContentInformation__c> postContentInformationList        =   [Select c.Post_content__c, c.Original_post_content__c, c.FeedItemUser__c, c.FeedCommentUser__c From ChatterCompliance_PostContentInformation__c c order by c.createddate asc limit 9000];
      list<ChatterCompliance_PostContentInformation__c> postContentInformationToUpdate    =   new list<ChatterCompliance_PostContentInformation__c>();
      // Creates/updates a chatterComplianceComment record when a chatter comment is created/deleted.
      List<ChatterComplianceComment__c> toUpdate = new List<ChatterComplianceComment__c>();
           
      Map<Id,ChatterCompliance__c> ccs              =   new Map<Id,ChatterCompliance__c>();
      Map<Id,ChatterComplianceComment__c> comments  =   new Map<Id,ChatterComplianceComment__c>();
      List<Id> tempList                             =   new List<Id>();

      if(trigger.isInsert){
          for(FeedComment f : trigger.new){
              tempList.add(f.FeedItemId);
          }
      }else if(trigger.isDelete){
           for(FeedComment f : trigger.old){
              tempList.add(f.id);
          }
      }

      for(ChatterCompliance__c cc : [Select id,PostId__c,Related_record_name__c,PostContent__c from ChatterCompliance__c where PostId__c in : tempList]){
          ccs.put(cc.PostId__c,cc);
      }

      for(ChatterComplianceComment__c ccc : [Select 
                                                    c.id,
                                                    c.Chatter_Compliance_Post_Content_Info__c,
                                                    c.commentId__c
                                             from ChatterComplianceComment__c c 
                                             where commentId__c in : tempList]){
          comments.put(ccc.commentId__c,ccc);
      }

      if(trigger.isInsert){
      
            Profile p = [select Id from Profile where Name='Chatter External User'];
            
            for(FeedComment f : trigger.new){
              
                ChatterCompliance__c relatedCompliance = ccs.get(f.feedItemId);

                if(relatedCompliance != null){
                    ChatterComplianceComment__c cc = new ChatterComplianceComment__c();
                    cc.ChatterCompliance__c = relatedCompliance.id;

                    for (ChatterCompliance_PostContentInformation__c c  :  postContentInformationList){
                        if(f.CreatedById == c.FeedCommentUser__c && f.CreatedDate > (system.now().addMinutes(-5))){
                          cc.Original_comment_content__c  =   c.Original_post_content__c;
                          cc.Chatter_Compliance_Post_Content_Info__c = c.Id;
                        //cc.PostContent__c = c.Post_content__c;
                        }
                    }

                    cc.commentContent__c     =   f.CommentBody;
                    cc.commentId__c          =   f.id;
                       
                    
                    
                    toUpdate.add(cc);
                }
            }
          insert toUpdate;
          ChatterCompliance_AdminSettings.sendEmails(toUpdate);
      }
      
      /* this will be logic when they edit Feeds 
      
      if(trigger.isUpdate){
      
            Profile p = [select Id from Profile where Name='Chatter External User'];
            
            for(FeedComment f : trigger.new){
              
                ChatterCompliance__c relatedCompliance = ccs.get(f.feedItemId);

                if(relatedCompliance != null){
                    ChatterComplianceComment__c cc = new ChatterComplianceComment__c();
                    cc.ChatterCompliance__c = relatedCompliance.id;

                    for (ChatterCompliance_PostContentInformation__c c  :  postContentInformationList){
                        if(f.CreatedById == c.FeedCommentUser__c && f.CreatedDate > (system.now().addMinutes(-5))){
                          cc.Original_comment_content__c  =   c.Original_post_content__c;
                          cc.Chatter_Compliance_Post_Content_Info__c = c.Id;
                        //cc.PostContent__c = c.Post_content__c;
                        }
                    }

                    cc.commentContent__c     =   f.CommentBody;
                    cc.commentId__c          =   f.id;
                       
                    
                    
                    toUpdate.add(cc);
                }
            }
          insert toUpdate;
          ChatterCompliance_AdminSettings.sendEmails(toUpdate);
      }*/
      
     
      if(trigger.isDelete){
          for(FeedComment f : trigger.old){
              ChatterComplianceComment__c item = comments.get(f.id);
              
              if(item != null){
                  item.deleted__c = true;
                  item.deleted_Date__c = Datetime.now();
                  item.deletedBy__c = Userinfo.getUserId();
                  toUpdate.add(item);
              
              if (item.Chatter_Compliance_Post_Content_Info__c !=null){
                    //item.Chatter_Compliance_Post_Content_Info__r.delete__c      =   true;
                    //item.Chatter_Compliance_Post_Content_Info__r.Deleted_by__c  =   Userinfo.getUserId() ;
                    //item.Chatter_Compliance_Post_Content_Info__r.Delete_date__c =   Datetime.now();
                
                    postContentInformationToUpdate.add(item.Chatter_Compliance_Post_Content_Info__r);
                }
              }
          }
          
          try{
            update postContentInformationToUpdate;
            upsert toUpdate;
          }catch (Exception e){
            system.debug('AN ERROR HAS OCCURRED:     ' + e);
          }
      }
}
}