/**
*   Chatter Compliance System (all classes, triggers and pages that start with ChatterCompliance)
*   FeedItem:   http://www.salesforce.com/us/developer/docs/api/Content/sforce_api_objects_feeditem.htm
*   @author     Arkus Dev Team
*/
trigger ChatterCompliance_FeedItemAfterInsertDelete_v1_2 on FeedItem bulk (after insert, after delete) {
    
    /**
    *   Creates/updates a chatterCompliance record when a chatter post is created/deleted.
    */

    List<ChatterCompliance__c> toUpdate = new List<ChatterCompliance__c>();
    List<Attachment> attaToInsert = new List<Attachment>();
    List<Id> attachments = new List<Id>();
    
    if(ArkusChatterComplianceSettings__c.getInstance('settings') != null){
        if(!ArkusChatterComplianceSettings__c.getInstance('settings').Chatter_Compliance_paused__c){
            String owner = ArkusChatterComplianceSettings__c.getInstance('settings').ChatterCompliance_owner__c;
            
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
            
            for(ChatterCompliance__c cc : [Select id,PostId_New__c,Related_record_name__c,(Select id from ChatterComplianceComments__r),(Select id from ChatterComplianceCommentsNew__r) from ChatterCompliance__c where PostId_New__c in : tempList]){
                ccs.put(cc.PostId_New__c,cc);
            }
            
            for(FeedItem fI : [Select id,parent.name from FeedItem where id =: tempList]){
                nameLinks.put(fI.id,fI.parent.name);
            }
            
            if(trigger.isInsert){
                ChatterCompliance__c cc;
                List<ID> attachmentIds = new List<ID>();
                for(FeedItem f : trigger.new){
                    cc = (ccs.get(f.id)!= null ? ccs.get(f.id) : new ChatterCompliance__c());
                    cc.Files_Attached__c = (f.type == 'ContentPost');
                    cc.delete__c = false;
                    cc.update__c = false;
                    cc.PostId_New__c = f.id;
                    cc.Post_Created_Date__c = f.createdDate;
                    cc.user__c = f.createdById;
                    cc.Related_record__c = f.parentId;
                    cc.Related_record_name__c = nameLinks.get(f.id);
                    cc.PostContent__c = f.body;
                    
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
                
                /*
                
                Map<ID, ContentVersion> cVersionMap = new Map<ID, ContentVersion>();
                
                if(!attachmentIds.isEmpty()){
                    
                    List<ContentVersion> cVersionList = [ SELECT c.Id, c.Title, c.ContentSize FROM ContentVersion c WHERE c.Id IN: attachmentIds ];
                    
                    for(ContentVersion cv: cVersionList){
                        cVersionMap.put(cv.Id, cv);
                    }
                    
                    for(ChatterCompliance__c cci : toUpdate){
                        if(cci.Files_Attached__c){
                            //cci.Attachment_name__c = cVersionMap.get(cci.Attachment__c).Title;
                            
                            // mark all the chatter compliance records that have an attachment, but the attachment is too big if it's over 5MB
                            if(cVersionMap.get(cci.Attachment__c).ContentSize >= 5242880){ // 1 megabyte = 1 048 576 bytes. The limit of file size is 5Mb.
                                cci.Files_attached_exceeded_limit__c = true;
                            }
                        }
                    }
                }
                
                */
                
                insert toUpdate;
                
                for(ChatterCompliance__c c : toUpdate){
                    ccs.put(c.PostId_New__c, c);
                }
                
                List<ChatterCompliance__c> toUpdateExceededLimit = new List<ChatterCompliance__c>();
                
                for(FeedItem fI : [Select id,contentData,contentFileName,ContentType,ContentSize from feedItem where id =: attachments]){
                    if(fI.ContentSize < 5242880){ // 1 megabyte = 1 048 576 bytes. The limit of file size is 5Mb.
                        Attachment a = new Attachment();
                        a.parentId = ccs.get(fI.id).id;
                        a.Name = fI.contentFileName;
                        a.ContentType = fI.ContentType;
                        a.Body = fI.contentData;
                        attaToInsert.add(a);
                    }else{
                        ccs.get(fI.id).Files_attached_exceeded_limit__c = true;
                        toUpdateExceededLimit.add(ccs.get(fI.id));
                    }
                }
                
                if((attaToInsert != null) && (attaToInsert.size() > 0)){
                    insert attaToInsert;
                }
                
                if((toUpdateExceededLimit != null) && (toUpdateExceededLimit.size() > 0)){
                    update toUpdateExceededLimit;
                }
                
                ChatterCompliance_AdminSettings.sendEmails(toUpdate);
                
            }
                
            if(trigger.isDelete){
                List<ChatterComplianceComment__c> toUpdateComments = new List<ChatterComplianceComment__c>();
                List<ChatterComplianceCommentNew__c> toUpdateCommentsNew = new List<ChatterComplianceCommentNew__c>();
                for(FeedItem f : trigger.old){
                    ChatterCompliance__c cc = ccs.get(f.id);
                    if(cc != null){
                        cc.delete__c = true;
                        cc.delete_Date__c = Datetime.now();
                        cc.deletedBy__c = Userinfo.getUserId();
                        for(ChatterComplianceComment__c ccc : cc.ChatterComplianceComments__r){
                            ccc.deleted__c = true;
                            ccc.deleted_Date__c = Datetime.now();
                            ccc.deletedBy__c = Userinfo.getUserId();
                            toUpdateComments.add(ccc);
                        }
                        for(ChatterComplianceCommentNew__c ccc : cc.ChatterComplianceCommentsNew__r){
                            ccc.deleted__c = true;
                            ccc.deleted_Date__c = Datetime.now();
                            ccc.deletedBy__c = Userinfo.getUserId();
                            toUpdateCommentsNew.add(ccc);
                        }
                        toUpdate.add(cc);
                    }
                }
                update toupdateComments;
                update toupdateCommentsNew;
                upsert toUpdate;
            }
        }
    }

}