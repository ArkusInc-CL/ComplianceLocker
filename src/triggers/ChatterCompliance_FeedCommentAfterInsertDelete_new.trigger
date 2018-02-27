/**
*   Chatter Compliance System (all classes, triggers and pages that start with ChatterCompliance)
*   @author     Arkus Dev Team
*/
trigger ChatterCompliance_FeedCommentAfterInsertDelete_new on FeedComment bulk (after delete, after insert, after update) {
    chatcomp__ArkusChatterComplianceSettings__c adminSettings  = chatcomp__ArkusChatterComplianceSettings__c.getInstance('settings');
 
if (adminSettings.chatcomp__Chatter_Compliance_paused__c==false){
      list<chatcomp__ChatterCompliance_PostContentInformation__c> postContentInformationList        =   [Select c.chatcomp__Post_content__c, c.chatcomp__Original_post_content__c, c.chatcomp__FeedItemUser__c, c.chatcomp__FeedCommentUser__c From chatcomp__ChatterCompliance_PostContentInformation__c c order by c.createddate asc limit 9000];
      list<chatcomp__ChatterCompliance_PostContentInformation__c> postContentInformationToUpdate    =   new list<chatcomp__ChatterCompliance_PostContentInformation__c>();
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
                                                    c.chatcomp__Chatter_Compliance_Post_Content_Info__c,
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

                    for (chatcomp__ChatterCompliance_PostContentInformation__c c  :  postContentInformationList){
                        if(f.CreatedById == c.chatcomp__FeedCommentUser__c && f.CreatedDate > (system.now().addMinutes(-5))){
                          cc.chatcomp__Original_comment_content__c  =   c.chatcomp__Original_post_content__c;
                          cc.chatcomp__Chatter_Compliance_Post_Content_Info__c = c.Id;
                        //cc.chatcomp__PostContent__c = c.chatcomp__Post_content__c;
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

                    for (chatcomp__ChatterCompliance_PostContentInformation__c c  :  postContentInformationList){
                        if(f.CreatedById == c.chatcomp__FeedCommentUser__c && f.CreatedDate > (system.now().addMinutes(-5))){
                          cc.chatcomp__Original_comment_content__c  =   c.chatcomp__Original_post_content__c;
                          cc.chatcomp__Chatter_Compliance_Post_Content_Info__c = c.Id;
                        //cc.chatcomp__PostContent__c = c.chatcomp__Post_content__c;
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
              
              if (item.chatcomp__Chatter_Compliance_Post_Content_Info__c !=null){
                    //item.chatcomp__Chatter_Compliance_Post_Content_Info__r.chatcomp__delete__c      =   true;
                    //item.chatcomp__Chatter_Compliance_Post_Content_Info__r.chatcomp__Deleted_by__c  =   Userinfo.getUserId() ;
                    //item.chatcomp__Chatter_Compliance_Post_Content_Info__r.chatcomp__Delete_date__c =   Datetime.now();
                
                    postContentInformationToUpdate.add(item.chatcomp__Chatter_Compliance_Post_Content_Info__r);
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