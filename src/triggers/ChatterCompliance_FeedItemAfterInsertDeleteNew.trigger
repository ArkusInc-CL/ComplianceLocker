/**
*   Chatter Compliance System (all classes, triggers and pages that start with ChatterCompliance)
*  FeedItem:   http://www.salesforce.com/us/developer/docs/api/Content/sforce_api_objects_feeditem.htm
*   @author     Arkus Dev Team
*/
trigger ChatterCompliance_FeedItemAfterInsertDeleteNew on FeedItem bulk (after insert, after delete) {
    ArkusChatterComplianceSettings__c       adminSettings       =   ArkusChatterComplianceSettings__c.getInstance('settings');
 
 //list<CollaborationGroupFeed> myCollaborationGroupFeedList=[Select c.FeedPost.ParentId, c.FeedPost.FeedItemId, c.FeedPostId From CollaborationGroupFeed c];
 
    if (adminSettings.Chatter_Compliance_paused__c==false){
    
        list<ChatterCompliance_PostContentInformation__c> postContentInformationList = [Select c.Post_content__c, c.Original_post_content__c, c.FeedItemUser__c, c.CreatedById From ChatterCompliance_PostContentInformation__c c order by c.createddate asc limit 1000];

        //  Creates/updates a chatterCompliance record when a chatter post is created/deleted.
      List<ChatterCompliance__c> toUpdate = new List<ChatterCompliance__c>();
      List<Attachment> attaToInsert = new List<Attachment>();
      List<Id> attachments = new List<Id>();
      list<ChatterCompliance_PostContentInformation__c> informationToUpdate = new list<ChatterCompliance_PostContentInformation__c>();
            
      if(ArkusChatterComplianceSettings__c.getInstance('settings') != null){
                  
          String owner                  =    ArkusChatterComplianceSettings__c.getInstance('settings').ChatterCompliance_owner__c;
          boolean doNotkeepAttachments  =    ArkusChatterComplianceSettings__c.getInstance('settings').Do_not_keep_any_attachments__c;
          
          
          Map<Id,ChatterCompliance__c> ccs = new Map<Id,ChatterCompliance__c>();
          Map<Id,String> nameLinks = new Map<Id,String>();
          List<Id> tempList = new List<Id>();
          
          if(trigger.isInsert){
              for(FeedItem f : trigger.new){
                  tempList.add(f.id);
              }
          }else if(trigger.isDelete){
              for(FeedItem f : trigger.old){
                  tempList.add(f.id);
              }
          }
          
          for(ChatterCompliance__c cc : [Select id,PostId__c,PostContentInformation__c,Related_record_name__c,(Select id,Chatter_Compliance_Post_Content_Info__c from ChatterComplianceComments__r) from ChatterCompliance__c where PostId__c in : tempList]){
              ccs.put(cc.PostId__c,cc);
          }
          
          for(FeedItem fI : [Select id,parent.name from FeedItem where id =: tempList]){
              nameLinks.put(fI.id,fI.parent.name);
          }
          
          if(trigger.isInsert){
              ChatterCompliance__c cc;
              List<ID> attachmentIds = new List<ID>();

              Profile p = [select Id from Profile where Name='Chatter External User'];
                                
              for(FeedItem f : trigger.new){

                  cc = (ccs.get(f.id)!= null ? ccs.get(f.id) : new ChatterCompliance__c());
                  cc.Files_Attached__c = (f.type == 'ContentPost');
                  cc.delete__c = false;
                  cc.update__c = false;
                  cc.PostId__c = f.id;
                  cc.Post_Created_Date__c = f.createdDate;
                  cc.user__c = f.createdById;
                  cc.Related_record__c = f.parentId;
                  cc.Related_record_name__c = nameLinks.get(f.id);
                  cc.PostContent__c = f.body;
                  
                  for(CollaborationGroup c:[Select c.Id,Name,CanHaveGuests  From CollaborationGroup c limit 2000]){
                    if (nameLinks.get(f.id) ==  c.Name  &&  c.CanHaveGuests ==  true){
                        cc.Posted_on_a_private_customer_group__c  =   true;
                    }
                  }
                  
                  if(UserInfo.getProfileId()==p.id){
                        cc.Is_a_customer_group_member__c  =   true ;
                  }
                  
                  for (ChatterCompliance_PostContentInformation__c c  :  postContentInformationList){
                    if(f.CreatedById == c.CreatedById && f.CreatedDate > (system.now().addMinutes(-5))){
                        cc.OriginalPostContent__c         =   c.Original_post_content__c;
                        cc.PostContentInformation__c      =   c.Id;
                        cc.PostContent__c                 =   c.Post_content__c;
                    }
                  }
                  
                  if(owner != null && owner != '') cc.OwnerId = owner;
                              
                  if(f.type == 'LinkPost'){
                      cc.PostContent__c = f.LinkUrl;
                  }
                  if(f.type == 'ContentPost'){
                    if(f.RelatedRecordId != null){
                        cc.Attachment__c = f.RelatedRecordId;
                        attachmentIds.add(f.RelatedRecordId);
                    }
                      attachments.add(f.id);
                  }
                  toUpdate.add(cc);
              }
              
              if (ArkusChatterComplianceSettings__c.getInstance('settings').Do_NOT_create_the_chatter_compliance_rec__c==false){
                  insert toUpdate;
                  toUpdate.clear();
              }
              
              for(ChatterCompliance__c c : toUpdate){
                  ccs.put(c.PostId__c, c);
              }
              
              List<ChatterCompliance__c> toUpdateExceededLimit = new List<ChatterCompliance__c>();
              
              for(FeedItem fI : [Select id,contentData,contentFileName,ContentType,ContentSize from feedItem where id =: attachments]){
                if(ccs!=null && ccs.size()>0 ){
                 if (doNotkeepAttachments==false){
                    if(fI.ContentSize < 5242880){ // 1 megabyte = 1 048 576 bytes. The limit of file size is 5Mb.
                        Attachment a  = new Attachment();
                        a.parentId    = ccs.get(fI.id).Id;
                        a.Name        = fI.contentFileName;
                        a.ContentType = fI.ContentType;
                        a.Body = fI.contentData;
                        if(a.parentId != ''){
                            attaToInsert.add(a);
                        }
                        
                        ccs.get(fI.id).Files_attached_exceeded_limit__c = false;
                    }else{  
                        ccs.get(fI.id).Files_attached_exceeded_limit__c = true;
                        toUpdateExceededLimit.add(ccs.get(fI.id));
                    }            
                 }
                } 
              }
              
              if((attaToInsert != null) && (attaToInsert.size() > 0)){
                  insert attaToInsert;
                  attaToInsert.clear();
              }

              if((toUpdateExceededLimit != null) && (toUpdateExceededLimit.size() > 0)){
                update toUpdateExceededLimit;
                toUpdateExceededLimit.clear();
              }

              ChatterCompliance_AdminSettings.sendEmails(toUpdate);
          }

          if(trigger.isDelete){
              List<ChatterComplianceComment__c> toUpdateComments = new List<ChatterComplianceComment__c>();
              for(FeedItem f : trigger.old){
                  ChatterCompliance__c cc = ccs.get(f.id);
                  if(cc != null){
                      cc.delete__c      = true;
                      cc.delete_Date__c = Datetime.now();
                      cc.deletedBy__c   = Userinfo.getUserId();

                      if (cc.PostContentInformation__c !=null){
                          //cc.PostContentInformation__r.delete__c        =   true;
                          //cc.PostContentInformation__r.Deleted_by__c    =   Userinfo.getUserId() ;
                          //cc.PostContentInformation__r.Delete_date__c   =   Datetime.now();
                      
                          informationToUpdate.add(cc.PostContentInformation__r);
                      }
                      
                      for(ChatterComplianceComment__c ccc : cc.ChatterComplianceComments__r){
                          ccc.deleted__c = true;
                          ccc.deleted_Date__c = Datetime.now();
                          ccc.deletedBy__c = Userinfo.getUserId();

                          if (ccc.Chatter_Compliance_Post_Content_Info__c                            !=   null){
                              //ccc.Chatter_Compliance_Post_Content_Info__r.delete__c         =   true;
                              //ccc.Chatter_Compliance_Post_Content_Info__r.Deleted_by__c     =   Userinfo.getUserId() ;
                              //ccc.Chatter_Compliance_Post_Content_Info__r.Delete_date__c    =   Datetime.now();
                       
                              informationToUpdate.add(ccc.Chatter_Compliance_Post_Content_Info__r);
                          }
                          
                          toUpdateComments.add(ccc);
                      }
                      toUpdate.add(cc);
                  }
              }
              try{
                  update informationToUpdate;
                  informationToUpdate.clear();
                  update toupdateComments;
                  toupdateComments.clear();
                  upsert toUpdate;
                  toUpdate.clear();
              }catch(Exception e){
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'We have found an exception:     ' + e);
              }
          }
      }
    }
}