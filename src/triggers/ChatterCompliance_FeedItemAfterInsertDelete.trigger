/**
*   Chatter Compliance System (all classes, triggers and pages that start with ChatterCompliance)
*   FeedItem:   http://www.salesforce.com/us/developer/docs/api/Content/sforce_api_objects_feeditem.htm
*   @author     Arkus Dev Team
*/
trigger ChatterCompliance_FeedItemAfterInsertDelete on FeedItem bulk (after insert,after update, after delete) {

	User u = [select id , profileId, Profile.UserLicense.Name from User where id = : userInfo.getUserId()];

    chatcomp__ArkusChatterComplianceSettings__c chatter = chatcomp__ArkusChatterComplianceSettings__c.getInstance('settings');
    system.debug('@@ chatter : '+chatter);
    
    if(chatter != null && u.Profile.UserLicense.Name != 'Chatter External' && u.Profile.UserLicense.Name != 'Chatter Free'){
        if(!chatter.chatcomp__Chatter_Compliance_paused__c){
            if(!ChatterCompliance_AdminSettings.existId(chatter.chatcomp__ChatterCompliance_Owner__c)){
                for(FeedItem f : trigger.new){
                    f.addError(ChatterCompliance_AdminSettings.msgCurrentOwnerDoesNotExists);
                    return;
                }
            }
        }
    }
    /***********************************************************/

    /**
    *   Creates/updates a chatterCompliance record when a chatter post is created/deleted.
    */
/*
    List<ChatterCompliance__c> toUpdate = new List<ChatterCompliance__c>();
    List<Attachment> attaToInsert = new List<Attachment>();
    List<Id> attachments = new List<Id>();

    if(chatcomp__ArkusChatterComplianceSettings__c.getInstance('settings') != null){
        if(!chatcomp__ArkusChatterComplianceSettings__c.getInstance('settings').chatcomp__Chatter_Compliance_paused__c){

            ChatterCompliance_AdminSettings.refreshOldCCRecords();

            String owner = chatcomp__ArkusChatterComplianceSettings__c.getInstance('settings').ChatterCompliance_owner__c;

            Map<Id,ChatterCompliance__c> ccs = new Map<Id,ChatterCompliance__c>();
            Map<Id,String> nameLinks = new Map<Id,String>();
            List<Id> tempList = new List<Id>();

            List<Id> createBy_IDs = new List<Id>();
            List<Id> feedParent_IDs = new List<Id>();

            if(trigger.isInsert){
                for(FeedItem f : trigger.new){
                    tempList.add(f.id);
                    createBy_IDs.add(f.createdById);
                    feedParent_IDs.add(f.parentId);
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

            Map<Id, User> usersMap = new Map<Id, User>([Select Profile.Name, Profile.UserLicense.Name From User Where Id IN :createBy_IDs]);

            if(trigger.isInsert){
                ChatterCompliance__c cc;
                List<ID> attachmentIds = new List<ID>();
                list<CollaborationGroup> collaborationGroupList = [Select c.Id, c.CollaborationType From CollaborationGroup c WHERE Id IN :feedParent_IDs];


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

                    Id id1 = f.ParentId;
                    Id id2 = f.InsertedById;
                    if(ChatterCompliance_AdminSettings.static_global_map2 != null){
                        if(ChatterCompliance_AdminSettings.static_global_map2.get(id1 + '~' + id2) != null){
                            cc.chatcomp__PostContentInformation__c = ChatterCompliance_AdminSettings.static_global_map2.get(id1 + '~' + id2);
                        }
                        if(ChatterCompliance_AdminSettings.static_global_map2.get(id1 + '~' + id2 + '~' + '1') != null){
                            cc.chatcomp__OriginalPostContent__c = ChatterCompliance_AdminSettings.static_global_map2.get(id1 + '~' + id2 + '~' + '1');
                        }
                    }

                for (CollaborationGroup collaborationGroup : collaborationGroupList){
                    if (collaborationGroup.Id == f.parentId){
                        cc.chatcomp__Is_a_customer_group_member__c = true;
                        if(collaborationGroup.CollaborationType == 'Private'){
                            cc.chatcomp__Posted_on_a_private_customer_group__c = true;
                        }
                    }
                }

                if(usersMap.get(f.createdById) != null){
                    if (usersMap.get(f.createdById).Profile.UserLicense.Name == 'Chatter External'){
                        cc.chatcomp__Post_made_by_an_outside_contact__c = true;
                        cc.chatcomp__Is_a_customer_group_member__c = true;
                        cc.chatcomp__Posted_on_a_private_customer_group__c = true;
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


                Map<ID, ContentVersion> cVersionMap = new Map<ID, ContentVersion>();

                if(!attachmentIds.isEmpty()){

                    List<ContentVersion> cVersionList = [ SELECT c.Id, c.Title, c.ContentSize FROM ContentVersion c WHERE c.Id IN: attachmentIds ];

                    for(ContentVersion cv: cVersionList){
                        cVersionMap.put(cv.Id, cv);
                    }

                    for(ChatterCompliance__c cci : toUpdate){
                        if(cci.Files_Attached__c){
                            cci.Attachment_name__c = cVersionMap.get(cci.Attachment__c).Title;

                            // mark all the chatter compliance records that have an attachment, but the attachment is too big if it's over 5MB
                            if(cVersionMap.get(cci.Attachment__c).ContentSize >= 5242880){ // 1 megabyte = 1 048 576 bytes. The limit of file size is 5Mb.
                                cci.chatcomp__Files_attached_exceeded_limit__c = true;
                            }
                        }
                    }
                }


                if(!chatter.chatcomp__Do_NOT_create_the_chatter_compliance_rec__c){
                    insert toUpdate;
                }

                for(ChatterCompliance__c c : toUpdate){
                    ccs.put(c.PostId_New__c, c);
                }

                List<ChatterCompliance__c> toUpdateExceededLimit = new List<ChatterCompliance__c>();

                for(FeedItem fI : [Select id,contentFileName,ContentType,ContentSize from feedItem where id =: attachments order by ContentSize asc]){
                    if(fI.ContentSize < 5242880){ // 1 megabyte = 1 048 576 bytes. The limit of file size is 5Mb.
                        Attachment a = new Attachment();
                        a.parentId = ccs.get(fI.id).id;
                        a.Name = fI.contentFileName;
                        a.ContentType = fI.ContentType;
                        if(!chatter.chatcomp__Do_not_keep_any_attachments__c){
                            a.Body = [SELECT contentData FROM FeedItem WHERE Id = :fI.Id].contentData;
                            attaToInsert.add(a);
                        }
                    }else{
                        ccs.get(fI.id).chatcomp__Files_attached_exceeded_limit__c = true;
                        toUpdateExceededLimit.add(ccs.get(fI.id));
                    }
                }

                if((attaToInsert != null) && (attaToInsert.size() > 0)){
                    if(!chatter.chatcomp__Do_NOT_create_the_chatter_compliance_rec__c){
                        insert attaToInsert;
                    }
                }

                if((toUpdateExceededLimit != null) && (toUpdateExceededLimit.size() > 0)){
                    if(!chatter.chatcomp__Do_NOT_create_the_chatter_compliance_rec__c){
                        update toUpdateExceededLimit;
                    }
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
                if(!chatter.chatcomp__Do_NOT_create_the_chatter_compliance_rec__c){
                    update toupdateComments;
                    update toupdateCommentsNew;
                    upsert toUpdate;
                }
            }
        }
    }
    */

    if(chatcomp__ArkusChatterComplianceSettings__c.getInstance('settings') != null){
        if(!chatcomp__ArkusChatterComplianceSettings__c.getInstance('settings').chatcomp__Chatter_Compliance_paused__c){
		    if (trigger.isInsert){
		    	ChatterCompliance_Utils.CreateFeedItemCompliance(trigger.new, true);
		    }else if(trigger.isUpdate){
		    	ChatterCompliance_Utils.CreateFeedItemCompliance(trigger.new, true);
		    }else if(trigger.isDelete){
		    	ChatterCompliance_Utils.DeleteFeedItemCompliance(trigger.old, null, true);
		    }
        }
    }
}