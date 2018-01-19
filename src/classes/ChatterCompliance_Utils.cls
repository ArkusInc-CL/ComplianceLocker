global class ChatterCompliance_Utils implements InstallHandler{
    //postInstall Script
    global void onInstall(InstallContext context){
        //execute only if previous version less than 2.0
        if(context.previousVersion() != NULL && context.previousVersion().major() < 2){
            ArkusChatterComplianceSettings__c ccSetting = ArkusChatterComplianceSettings__c.getInstance('settings');
            //if custom setting is null do nothing
            if(ccSetting != null){
                if(ccSetting.selectedEmailSubject__c == null || ccSetting.selectedEmailSubject__c == ''){
                    ccSetting.selectedEmailSubject__c = 'New Chatter Compliance';
                    update ccSetting;
                }            
                Id ScheduleJobId = ccSetting.Scheduled_Job_Id__c;
                //if scheduled job is null do nothing
                if(ScheduleJobId != null){
                    List<CronTrigger> AAJ = [SELECT Id FROM CronTrigger WHERE Id =: ScheduleJobId];
                    //if AsyncApexJob is not null create new scheduled job else scheduled job id = null
                    if(!AAJ.isEmpty()){
                        if(ccSetting.DeleteFeedItem__c){
                            ccSetting.Delete_original_content_schedule_job_id__c =
                                System.schedule('Arkus Compliance for Chatter [delete original chatter posts]', '0 0 5 * * ?', new ChatterCompliance_OriginalCheckDeleted());
                            ccSetting.Time_to_delete_original_records__c = ccSetting.Time_to_delete__c;
                            update ccSetting;
                        }
                    }
                    else{
                        ccSetting.Scheduled_Job_Id__c = null;
                        update ccSetting;
                    }
                }
            }
        }
        
        Id recordtypeid = ChatterCompliance_Word_blocker__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Word').getRecordTypeId();
        List<ChatterCompliance_Word_blocker__c> lstWord= [Select Id, RecordTypeId From ChatterCompliance_Word_blocker__c where RecordTypeId = null limit 8000];
        for(ChatterCompliance_Word_blocker__c word : lstWord){
            word.RecordTypeId = recordtypeid;
        }
        update lstWord;
    }

    /**************************************
    ***          FEED ITEM              ***
    **************************************/


    /**************************
    ***        CREATE       ***
    **************************/

    //   Creates/updates a chatterCompliance record when a chatter post is created.
    public static void CreateFeedItemCompliance(list<FeedItem> items, boolean isTrigger){
        list<ID> attachmentIds              = new list<ID>();
        list<Id> tempList                   = new list<Id>();
        list<Id> createBy_IDs               = new list<Id>();
        list<Id> feedParent_IDs             = new list<Id>();
        list<Id> attachments                = new list<Id>();
        list<Attachment> attaToInsert       = new list<Attachment>();
        list<ChatterCompliance__c> toUpdate = new list<ChatterCompliance__c>();

        map<Id,String> nameLinks = new map<Id,String>();
        map<Id,ChatterCompliance__c> ccs = new map<Id,ChatterCompliance__c>();

        ArkusChatterComplianceSettings__c chatter = ArkusChatterComplianceSettings__c.getInstance('settings');

        String owner = ArkusChatterComplianceSettings__c.getInstance('settings').ChatterCompliance_owner__c;

        for(FeedItem f : items){
            tempList.add(f.id);
            createBy_IDs.add(f.createdById);
            feedParent_IDs.add(f.parentId);
        }

         for(ChatterCompliance__c cc : [Select id,PostId_New__c,Related_record_name__c,(Select id from ChatterComplianceComments__r),(Select id from ChatterComplianceCommentsNew__r) from ChatterCompliance__c where PostId_New__c in : tempList]){
            ccs.put(cc.PostId_New__c,cc);
         }

         for(FeedItem fI : [Select id,parent.name from FeedItem where id =: tempList]){
            nameLinks.put(fI.id,fI.parent.name);
         }

         map<Id, User> usersMap = new map<Id, User>([Select Profile.Name, Profile.UserLicense.Name From User Where Id IN :createBy_IDs]);

         ChatterCompliance__c cc;
         list<CollaborationGroup> collaborationGroupList = [Select c.Id, c.CollaborationType From CollaborationGroup c WHERE Id IN :feedParent_IDs];

        for(FeedItem f : items){
            cc = (ccs.get(f.id)!= null ? ccs.get(f.id) : new ChatterCompliance__c());
            cc.Files_Attached__c = (f.type == 'ContentPost');
            cc.delete__c = false;
            cc.update__c = false;
            if(f.Type == 'Activity Event'){
                cc.TaskPost__c = true;
            }
            else{
                cc.TaskPost__c = false;
            }
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
                    cc.PostContentInformation__c = ChatterCompliance_AdminSettings.static_global_map2.get(id1 + '~' + id2);
                }
                if(ChatterCompliance_AdminSettings.static_global_map2.get(id1 + '~' + id2 + '~' + '1') != null){
                    cc.OriginalPostContent__c = ChatterCompliance_AdminSettings.static_global_map2.get(id1 + '~' + id2 + '~' + '1');
                }
            }

            for (CollaborationGroup collaborationGroup : collaborationGroupList){
                if (collaborationGroup.Id == f.parentId){
                    cc.Is_a_customer_group_member__c = true;
                    if(collaborationGroup.CollaborationType == 'Private'){
                        cc.Posted_on_a_private_customer_group__c = true;
                    }
                }
            }

            if(usersMap.get(f.createdById) != null){
                if (usersMap.get(f.createdById).Profile.UserLicense.Name == 'Chatter External'){
                    cc.Post_made_by_an_outside_contact__c = true;
                    cc.Is_a_customer_group_member__c = true;
                    cc.Posted_on_a_private_customer_group__c = true;
                }
            }

            if(owner != null && owner != '') cc.OwnerId = owner;

            if(f.type == 'LinkPost') cc.PostContent__c = f.LinkUrl;

            if(f.type == 'ContentPost'){
                if(f.RelatedRecordId != null){
                    cc.Attachment__c = f.RelatedRecordId;
                    attachmentIds.add(f.RelatedRecordId);
                }
                attachments.add(f.id);

            }
            toUpdate.add(cc);
       }

       map<ID, ContentVersion> cVersionMap = new map<ID, ContentVersion>();
       map<ID, ContentDocument> cDocumentMap = new map<ID, ContentDocument>();

       if(!attachmentIds.isEmpty()){

            list<ContentVersion> cVersionList = [SELECT c.Id, c.Title, c.ContentSize FROM ContentVersion c WHERE c.Id IN: attachmentIds];

            for(ContentVersion cv: cVersionList){
                cVersionMap.put(cv.Id, cv);
            }

            for(ContentDocument cd : [SELECT LatestPublishedVersionId, LatestPublishedVersion.Title, LatestPublishedVersion.ContentSize FROM ContentDocument WHERE LatestPublishedVersionId IN: attachmentIds]){
                cDocumentMap.put(cd.LatestPublishedVersionId, cd);
            }

            for(ChatterCompliance__c cci : toUpdate){
                if(cci.Files_Attached__c){
                    if(cVersionMap.get(cci.Attachment__c) != null){
                        cci.Attachment_name__c = cVersionMap.get(cci.Attachment__c).Title;

                        // mark all the chatter compliance records that have an attachment, but the attachment is too big if it's over 5MB
                        if(cVersionMap.get(cci.Attachment__c).ContentSize >= 5242880){ // 1 megabyte = 1 048 576 bytes. The limit of file size is 5Mb.
                            cci.Files_attached_exceeded_limit__c = true;
                        }
                    }
                    if(cDocumentMap.get(cci.Attachment__c) != null){
                        cci.Attachment_name__c = cDocumentMap.get(cci.Attachment__c).LatestPublishedVersion.Title;

                        // mark all the chatter compliance records that have an attachment, but the attachment is too big if it's over 5MB
                        if(cDocumentMap.get(cci.Attachment__c).LatestPublishedVersion.ContentSize >= 5242880){ // 1 megabyte = 1 048 576 bytes. The limit of file size is 5Mb.
                            cci.Files_attached_exceeded_limit__c = true;
                        }
                    }
                }
            }
        }
        if(!chatter.Do_NOT_create_the_chatter_compliance_rec__c){
            upsert toUpdate;
        }

        for(ChatterCompliance__c c : toUpdate){
            ccs.put(c.PostId_New__c, c);
        }

        list<ChatterCompliance__c> toUpdateExceededLimit = new list<ChatterCompliance__c>();

        for(FeedItem fI : [Select id,
        					contentFileName,
        					ContentType,ContentSize from feedItem where id =: attachments order by ContentSize asc]){
            if(fI.ContentSize < 5242880){ // 1 megabyte = 1 048 576 bytes. The limit of file size is 5Mb.
                Attachment a = new Attachment();
                a.parentId = ccs.get(fI.id).id;
                a.Name = fI.contentFileName;
                a.ContentType = fI.ContentType;
                    if(!chatter.Do_not_keep_any_attachments__c){
                        a.Body = [SELECT contentData FROM FeedItem WHERE Id = :fI.Id].contentData;
                        attaToInsert.add(a);
                    }
            }else{
                  ccs.get(fI.id).Files_attached_exceeded_limit__c = true;
                  toUpdateExceededLimit.add(ccs.get(fI.id));
            }
            
            if((attaToInsert != null) && (attaToInsert.size() > 0)){
                if(!chatter.Do_NOT_create_the_chatter_compliance_rec__c || !isTrigger){
                    insert attaToInsert;
                }
                attaToInsert.clear();
            }
        }  

            if((toUpdateExceededLimit != null) && (toUpdateExceededLimit.size() > 0)){
                if(!chatter.Do_NOT_create_the_chatter_compliance_rec__c || !isTrigger){
                    update toUpdateExceededLimit;
                }
            }

            if(isTrigger){
                ChatterCompliance_AdminSettings.sendEmails(toUpdate);
            }
    }

    /**************************
    ***        DELETE       ***
    **************************/
    //   Creates/updates a chatterCompliance record when a chatter post is deleted.
    public static void DeleteFeedItemCompliance(list<FeedItem> items, list<Id> itemsId, boolean isTrigger){
        list<ChatterCompliance__c> toUpdate = new list<ChatterCompliance__c>();
        list<Id> tempList = new list<Id>();
        list<ChatterComplianceComment__c> toUpdateComments = new list<ChatterComplianceComment__c>();
        list<ChatterComplianceCommentNew__c> toUpdateCommentsNew = new list<ChatterComplianceCommentNew__c>();

        map<Id,String> nameLinks = new map<Id,String>();
        map<Id,ChatterCompliance__c> ccs = new map<Id,ChatterCompliance__c>();

        ArkusChatterComplianceSettings__c chatter = ArkusChatterComplianceSettings__c.getInstance('settings');

        if(items != null){
            for(FeedItem f : items){
                tempList.add(f.id);
            }
        }
        else{
            templist = itemsId;
        }

        for(ChatterCompliance__c cc : [Select id,PostId_New__c,Related_record_name__c,(Select id from ChatterComplianceComments__r),(Select id from ChatterComplianceCommentsNew__r) from ChatterCompliance__c where PostId_New__c in : tempList]){
            ccs.put(cc.PostId_New__c,cc);
        }

        for(FeedItem fI : [Select id,parent.name from FeedItem where id =: tempList]){
            nameLinks.put(fI.id,fI.parent.name);
        }

        for(Id f : tempList){
            ChatterCompliance__c cc = ccs.get(f);
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
        if(!chatter.Do_NOT_create_the_chatter_compliance_rec__c || !isTrigger){
            update toupdateComments;
            update toupdateCommentsNew;
            upsert toUpdate;
        }

    }

    /**************************************
    ***          FEED COMMENT           ***
    **************************************/


    /**************************
    ***        CREATE       ***
    **************************/

    //   Creates/updates a chatterCompliance record when a chatter comment is created.
   /* public static void CreateFeedCommentCompliance(list<FeedComment> items, boolean isTrigger){
        list<Id> relatedRecordIds = new list<Id>();
        list<Id> attachments = new list<Id>();
        list<Attachment> attaToInsert = new list<Attachment>();

        map<ID,ContentVersion> contentVersionMap = new map<Id,ContentVersion>();
        map<ID,ContentDocument> contentDocumentMap = new map<Id,ContentDocument>();

        ArkusChatterComplianceSettings__c chatter = ArkusChatterComplianceSettings__c.getInstance('settings');


        for(FeedComment fc : items){
            relatedRecordIds.add(fc.RelatedRecordId);
        }

        for (ContentVersion contentVersion:[select title, filetype, Id, contentSize from ContentVersion WHERE Id IN :relatedRecordIds]){
            contentVersionMap.put(contentVersion.id,contentVersion);
        }

        for (ContentDocument contentDocument:[SELECT LatestPublishedVersionId,LatestPublishedVersion.filetype, LatestPublishedVersion.Title, LatestPublishedVersion.ContentSize FROM ContentDocument WHERE LatestPublishedVersionId IN: relatedRecordIds]){
                contentDocumentMap.put(contentDocument.id,contentDocument);
        }

        ChatterCompliance_AdminSettings.refreshOldCCRecords();

        if(ChatterCompliance_AdminSettings.IsChatterExternalOrFreeUser(UserInfo.getUserId()) == false){
            // For non chatter free users
            list<ChatterComplianceComment__c> toUpdate = new list<ChatterComplianceComment__c>();
            list<Id> tempList = new list<Id>();
            list<ID> attachmentIds = new list<ID>();
            list<ChatterCompliance__c> toUpdateExceededLimit = new list<ChatterCompliance__c>();

            map<Id,ChatterCompliance__c> ccs = new map<Id,ChatterCompliance__c>();
            map<Id,ChatterComplianceComment__c> comments = new map<Id,ChatterComplianceComment__c>();

            for(FeedComment f : items){
                tempList.add(f.Id);
                tempList.add(f.FeedItemId);
            }

            for(ChatterCompliance__c cc : [Select id,PostId_New__c,Related_record_name__c,PostContent__c from ChatterCompliance__c where PostId_New__c in : tempList]){
                ccs.put(cc.PostId_New__c,cc);
            }

            for(ChatterComplianceComment__c ccc : [Select id,Attachment__c,commentId_New__c from ChatterComplianceComment__c where commentId_New__c in : tempList]){
                comments.put(ccc.Attachment__c,ccc);
                comments.put(ccc.commentId_New__c, ccc);
            }

            for(FeedComment f : items){
                ChatterCompliance__c relatedCompliance = ccs.get(f.feedItemId);
                if(relatedCompliance != null){
                    ChatterComplianceComment__c cc = new ChatterComplianceComment__c();
                    cc.ChatterCompliance__c = relatedCompliance.id;
                    cc.commentContent__c = f.CommentBody;
                    cc.commentId_New__c = f.id;

                    Id id1 = f.ParentId;
                    Id id2 = f.FeedItemId;
                    if(ChatterCompliance_AdminSettings.static_global_map != null){
                        if(ChatterCompliance_AdminSettings.static_global_map.get(id1 + '~' + id2) != null){
                            cc.Chatter_Compliance_Post_Content_Info__c = ChatterCompliance_AdminSettings.static_global_map.get(id1 + '~' + id2);
                        }
                        if(ChatterCompliance_AdminSettings.static_global_map.get(id1 + '~' + id2 + '~' + '1') != null){
                            cc.Original_comment_content__c = ChatterCompliance_AdminSettings.static_global_map.get(id1 + '~' + id2 + '~' + '1');
                        }
                    }

                    if(f.FeedItemId != null){
                        cc.Attachment__c = f.RelatedRecordId;
                        if(contentVersionMap.get(f.RelatedRecordId) != null){
                            cc.Attachment_name__c = contentVersionMap.get(f.RelatedRecordId).title;
                        }
                        else{
                            ContentVersion cv = getContentVersionFromContentDocument(f, contentDocumentMap);
                            if(cv != null){
                                cc.Attachment_name__c = cv.title;
                            }
                            else{
                                cc.Attachment_name__c = '';
                            }
                        }
                        attachmentIds.add(f.FeedItemId);
                    }
                        attachments.add(f.id);
                        toUpdate.add(cc);

                }
            }

            if(!chatter.Do_NOT_create_the_chatter_compliance_rec__c || !isTrigger){
                insert toUpdate;
            }

            if((attaToInsert != null) && (attaToInsert.size() > 0)){
                if(!chatter.Do_NOT_create_the_chatter_compliance_rec__c || !isTrigger){
                    insert attaToInsert;
                }
                attaToInsert.clear();
            }

            if((toUpdateExceededLimit != null) && (toUpdateExceededLimit.size() > 0)){
                if(!chatter.Do_NOT_create_the_chatter_compliance_rec__c || !isTrigger){
                    update toUpdateExceededLimit;
                }
                toUpdateExceededLimit.clear();
            }


            for(FeedComment feedComment : items){
                ChatterComplianceComment__c myChatterComplianceComment = new ChatterComplianceComment__c();
                ContentVersion contentVersion = contentVersionMap.get(feedComment.RelatedRecordId);
                if(contentVersion == null){
                    contentVersion = getContentVersionFromContentDocument(feedComment, ContentDocumentMap);
                }

                Attachment a = new Attachment();

                if(contentVersion != null && contentVersion.ContentSize > 5242880){
                    myChatterComplianceComment.Files_attached_exceeded_size_limit__c = true;
                }

                for (ChatterComplianceComment__c chatterComplianceComment : toUpdate){
                    if (chatterComplianceComment.commentId_New__c == feedComment.Id){
                        a.parentId = chatterComplianceComment.Id;
                        myChatterComplianceComment = chatterComplianceComment;
                        if(contentVersion != null){
                            chatterComplianceComment.Files_Attached__c = true;
                        }
                    }
                }
                if(contentVersion != null){
                    a.Name = contentVersion.title + '.' + contentVersion.filetype.toLowerCase();
                    if(contentVersion.ContentSize < 5242880){
                        if(!chatter.Do_not_keep_any_attachments__c){
                            List<ContentVersion> lVersion = [SELECT VersionData FROM ContentVersion WHERE Id = :contentVersion.Id];
                            if(lVersion.size() > 0){
                                a.Body = lVersion[0].VersionData;
                            }
                            else{
                                List<ContentDocument> lDocument = [Select LatestPublishedVersion.VersionData from ContentDocument WHERE latestPublishedVersionId =: contentVersion.Id];
                                a.Body = lDocument[0].LatestPublishedVersion.VersionData;
                            }
                            if(a.parentId != NULL){
                                attaToInsert.add(a);
                            }
                        }
                    }else{
                        myChatterComplianceComment.Files_attached_exceeded_size_limit__c = true;
                    }
                }
                if(!chatter.Do_NOT_create_the_chatter_compliance_rec__c || !isTrigger){
                    if(myChatterComplianceComment.Id != NULL){
                        update myChatterComplianceComment;
                    }
                    }
            }

            if(!chatter.Do_NOT_create_the_chatter_compliance_rec__c || !isTrigger){
                insert attaToInsert;
            }

            if (isTrigger == true){
                if(!chatter.Do_NOT_create_the_chatter_compliance_rec__c){
                    ChatterCompliance_AdminSettings.sendEmails(toUpdate);
                }else{
                    ChatterCompliance_AdminSettings.sendEmails(items);
                }
            }
        }else{
            // For Chatter Free Users
            list<ChatterComplianceCommentNew__c> toUpdate = new list<ChatterComplianceCommentNew__c>();
            list<Id> tempList = new list<Id>();

            map<Id,ChatterCompliance__c> ccs = new map<Id,ChatterCompliance__c>();
            map<Id,ChatterComplianceCommentNew__c> comments = new map<Id,ChatterComplianceCommentNew__c>();

          if(ArkusChatterComplianceSettings__c.getInstance('settings') != null){
            String owner = ArkusChatterComplianceSettings__c.getInstance('settings').ChatterCompliance_owner__c;
            ChatterComplianceCommentNew__c myChatterComplianceCommentNew;
            list<ChatterComplianceCommentNew__c> toUpdateCCCommentsNew = new list<ChatterComplianceCommentNew__c>();

            for(FeedComment f : items){
                tempList.add(f.FeedItemId);
            }

            for(ChatterCompliance__c cc : [Select id,PostId_New__c,Related_record_name__c,PostContent__c from ChatterCompliance__c where PostId_New__c in : tempList]){
                ccs.put(cc.PostId_New__c,cc);
            }

            for(ChatterComplianceCommentNew__c ccc : [Select id,commentId__c from ChatterComplianceCommentNew__c where commentId__c in : tempList]){
                comments.put(ccc.commentId__c,ccc);
            }

            for(FeedComment f : items){
                ChatterCompliance__c relatedCompliance = ccs.get(f.feedItemId);
                if(relatedCompliance != null){
                    ChatterComplianceCommentNew__c cc = new ChatterComplianceCommentNew__c();
                    cc.ChatterCompliance__c = relatedCompliance.id;
                    cc.commentContent__c = f.CommentBody;
                    cc.commentId__c = f.id;
                    cc.OwnerId = owner;

                    Id id1 = f.ParentId;
                    Id id2 = f.FeedItemId;
                    if(ChatterCompliance_AdminSettings.static_global_map != null){
                        if(ChatterCompliance_AdminSettings.static_global_map.get(id1 + '~' + id2) != null){
                            cc.Chatter_Compliance_Post_Content_Info__c = ChatterCompliance_AdminSettings.static_global_map.get(id1 + '~' + id2);
                        }
                        if(ChatterCompliance_AdminSettings.static_global_map.get(id1 + '~' + id2 + '~' + '1') != null){
                            cc.Original_comment_content__c = ChatterCompliance_AdminSettings.static_global_map.get(id1 + '~' + id2 + '~' + '1');
                        }
                    }

                    toUpdate.add(cc);
                }
            }

            if(!chatter.Do_NOT_create_the_chatter_compliance_rec__c || !isTrigger){
                insert toUpdate;
            }

            for(FeedComment feedComment : items){

                myChatterComplianceCommentNew = null;

                for (ChatterComplianceCommentNew__c cccNew : toUpdate){
                    if (cccNew.commentId__c == feedComment.Id){
                        myChatterComplianceCommentNew = cccNew;
                    }
                }

                ContentVersion contentVersion = contentVersionMap.get(feedComment.RelatedRecordId);
                if (contentVersion == null){
                    contentVersion = getContentVersionFromContentDocument(feedComment, ContentDocumentMap);
                }

                if(contentVersion != null && myChatterComplianceCommentNew != null){

                    myChatterComplianceCommentNew.Files_Attached__c = true;
                    myChatterComplianceCommentNew.Attachment__c = feedComment.RelatedRecordId;
                    myChatterComplianceCommentNew.Attachment_name__c = contentVersion.title;

                    Attachment a = new Attachment();
                    a.parentId = myChatterComplianceCommentNew.Id;
                    a.Name = contentVersion.title + '.' + contentVersion.filetype.toLowerCase();

                    if(contentVersion.ContentSize < 5242880){
                        if(!chatter.Do_not_keep_any_attachments__c){
                            List<ContentVersion> lVersionFree = [SELECT VersionData FROM ContentVersion WHERE Id = :contentVersion.Id];
                            if(lVersionFree.size() > 0){
                                a.Body = lVersionFree[0].VersionData;
                            }
                            else{
                                List<ContentDocument> lDocumentFree = [Select LatestPublishedVersion.VersionData from ContentDocument WHERE latestPublishedVersionId =: contentVersion.Id];
                                a.Body = lDocumentFree[0].LatestPublishedVersion.VersionData;
                            }
                            if(a.parentId != NULL){
                                attaToInsert.add(a);
                            }
                        }
                    }
                    else{
                        myChatterComplianceCommentNew.Files_attached_exceeded_size_limit__c = true;
                    }
                    toUpdateCCCommentsNew.add(myChatterComplianceCommentNew);
                    upsert toUpdateCCCommentsNew;
                    toUpdateCCCommentsNew.clear();
                }
            }

            if(!chatter.Do_NOT_create_the_chatter_compliance_rec__c || !isTrigger){

                upsert attaToInsert;
            }

            if (isTrigger ==true ){
                if(!chatter.Do_NOT_create_the_chatter_compliance_rec__c){
                    ChatterCompliance_AdminSettings.sendEmails(toUpdate);
                }else{
                    ChatterCompliance_AdminSettings.sendEmails(items);
                }
            }
        }
     }
 }*/



     //Creates/updates a chatterCompliance record when a chatter comment is created.
    public static void CreateFeedCommentComplianceNEW(list<FeedComment> items, boolean isTrigger){
        ArkusChatterComplianceSettings__c chatter = ArkusChatterComplianceSettings__c.getInstance('settings');
        String owner = chatter.ChatterCompliance_owner__c;
        map<ID,ContentVersion> contentVersionMap = new map<Id,ContentVersion>();
        map<ID,ContentDocument> contentDocumentMap = new map<Id,ContentDocument>();
        map<Id,ChatterCompliance__c> ccs = new map<Id,ChatterCompliance__c>();
        list<Id> relatedRecordIds = new list<Id>();
        list<Id> userId = new list<Id>();
        list<ChatterComplianceComment__c> toUpdate = new list<ChatterComplianceComment__c>();
        list<Id> tempList = new list<Id>();
        list<ChatterCompliance__c> toUpdateExceededLimit = new list<ChatterCompliance__c>();
        list<Attachment> attaToInsert = new list<Attachment>();
        list<ChatterComplianceCommentNew__c> toUpdateNew = new list<ChatterComplianceCommentNew__c>();
        list<ChatterComplianceCommentNew__c> toUpdateCCCommentsNew = new list<ChatterComplianceCommentNew__c>();
        list<ChatterComplianceComment__c> toUpdateCCComments = new list<ChatterComplianceComment__c>();


        for(FeedComment f : items){
            userId.add(f.InsertedById);
            if(f.RelatedRecordId != null){
                relatedRecordIds.add(f.RelatedRecordId);
            }
            tempList.add(f.Id);
            tempList.add(f.FeedItemId);
        }

        for (ContentVersion contentVersion:[select title, filetype, Id, contentSize from ContentVersion WHERE Id IN :relatedRecordIds]){
            contentVersionMap.put(contentVersion.id,contentVersion);
        }

        for (ContentDocument contentDocument:[SELECT LatestPublishedVersionId,LatestPublishedVersion.filetype, LatestPublishedVersion.Title, LatestPublishedVersion.ContentSize FROM ContentDocument WHERE LatestPublishedVersionId IN: relatedRecordIds]){
                contentDocumentMap.put(contentDocument.id,contentDocument);
        }

        for(ChatterCompliance__c cc : [Select id,PostId_New__c,Related_record_name__c,PostContent__c from ChatterCompliance__c where PostId_New__c in : tempList]){
            ccs.put(cc.PostId_New__c,cc);
        }

        map<Id, boolean> mapExternalOrFree = ChatterCompliance_AdminSettings.IsChatterExternalOrFreeUser(userId);

        ChatterCompliance_AdminSettings.refreshOldCCRecords();

        //Here the FeedComments are replicated creating ChatterCompilanceComments or ChatterCompilanceCommentNew objects
        for(FeedComment f : items){
            if(!mapExternalOrFree.get(f.InsertedById)){
                 // For non chatter free users
                ChatterCompliance__c relatedCompliance = ccs.get(f.feedItemId);
                if(relatedCompliance != null){
                    ChatterComplianceComment__c cc = new ChatterComplianceComment__c();
                    cc.ChatterCompliance__c = relatedCompliance.id;
                    cc.commentContent__c = f.CommentBody;
                    cc.commentId_New__c = f.id;

                    Id id1 = f.ParentId;
                    Id id2 = f.FeedItemId;
                    if(ChatterCompliance_AdminSettings.static_global_map != null){
                        if(ChatterCompliance_AdminSettings.static_global_map.get(id1 + '~' + id2) != null){
                            cc.Chatter_Compliance_Post_Content_Info__c = ChatterCompliance_AdminSettings.static_global_map.get(id1 + '~' + id2);
                        }
                        if(ChatterCompliance_AdminSettings.static_global_map.get(id1 + '~' + id2 + '~' + '1') != null){
                            cc.Original_comment_content__c = ChatterCompliance_AdminSettings.static_global_map.get(id1 + '~' + id2 + '~' + '1');
                        }
                    }

                    if(f.FeedItemId != null){
                        cc.Attachment__c = f.RelatedRecordId;
                        if(contentVersionMap.get(f.RelatedRecordId) != null){
                            cc.Attachment_name__c = contentVersionMap.get(f.RelatedRecordId).title;
                        }
                        else{
                            ContentVersion cv = getContentVersionFromContentDocument(f, contentDocumentMap);
                            if(cv != null){
                                cc.Attachment_name__c = cv.title;
                            }
                            else{
                                cc.Attachment_name__c = '';
                            }
                        }
                    }
                    toUpdate.add(cc);
                }

            }
            else{
                ChatterCompliance__c relatedCompliance = ccs.get(f.feedItemId);
                if(relatedCompliance != null){
                    ChatterComplianceCommentNew__c cc = new ChatterComplianceCommentNew__c();
                    cc.ChatterCompliance__c = relatedCompliance.id;
                    cc.commentContent__c = f.CommentBody;
                    cc.commentId__c = f.id;
                    cc.OwnerId = owner;

                    Id id1 = f.ParentId;
                    Id id2 = f.FeedItemId;
                    if(ChatterCompliance_AdminSettings.static_global_map != null){
                        if(ChatterCompliance_AdminSettings.static_global_map.get(id1 + '~' + id2) != null){
                            cc.Chatter_Compliance_Post_Content_Info__c = ChatterCompliance_AdminSettings.static_global_map.get(id1 + '~' + id2);
                        }
                        if(ChatterCompliance_AdminSettings.static_global_map.get(id1 + '~' + id2 + '~' + '1') != null){
                            cc.Original_comment_content__c = ChatterCompliance_AdminSettings.static_global_map.get(id1 + '~' + id2 + '~' + '1');
                        }
                    }

                    if(f.FeedItemId != null){
                        cc.Attachment__c = f.RelatedRecordId;
                        if(contentVersionMap.get(f.RelatedRecordId) != null){
                            cc.Attachment_name__c = contentVersionMap.get(f.RelatedRecordId).title;
                        }
                        else{
                            ContentVersion cv = getContentVersionFromContentDocument(f, contentDocumentMap);
                            if(cv != null){
                                cc.Attachment_name__c = cv.title;
                            }
                            else{
                                cc.Attachment_name__c = '';
                            }
                        }
                    }

                    toUpdateNew.add(cc);
                }
            }
        }
        if(!chatter.Do_NOT_create_the_chatter_compliance_rec__c || !isTrigger){
            insert toUpdate;
            insert toUpdateNew;
        }

        map<Id, ChatterComplianceCommentNew__c> mapCCNew = new map<Id, ChatterComplianceCommentNew__c>();
        for (ChatterComplianceCommentNew__c cccNew : toUpdateNew){
            mapCCNew.put(cccNew.commentId__c, cccNew );
        }

        map<Id, ChatterComplianceComment__c> mapCC = new map<Id, ChatterComplianceComment__c>();
        for (ChatterComplianceComment__c ccc : toUpdate){
            mapCC.put(ccc.commentId_New__c, ccc );
        }

        //Here the attachments are added to the Objects creted in the previous for
        for(FeedComment feedComment : items){
            if(!mapExternalOrFree.get(feedComment.InsertedById)){
                //For Standard Users
                ChatterComplianceComment__c myChatterComplianceComment = mapCC.get(feedComment.Id);

                ContentVersion contentVersion = contentVersionMap.get(feedComment.RelatedRecordId);
                if(contentVersion == null){
                    contentVersion = getContentVersionFromContentDocument(feedComment, ContentDocumentMap);
                }
                // if there is an attachmente copy it, if not do nothing
                if(contentVersion != null && myChatterComplianceComment != null){
                    Attachment a = new Attachment();

                    if(contentVersion.ContentSize > 5242880){
                        myChatterComplianceComment.Files_attached_exceeded_size_limit__c = true;
                    }

                    a.parentId = myChatterComplianceComment.Id;

                    myChatterComplianceComment.Files_Attached__c = true;

                    a.Name = contentVersion.title + '.' + contentVersion.filetype.toLowerCase();
                    if(contentVersion.ContentSize < 5242880){
                        if(!chatter.Do_not_keep_any_attachments__c){
                            List<ContentVersion> lVersion = [SELECT VersionData FROM ContentVersion WHERE Id = :contentVersion.Id];
                            if(lVersion.size() > 0){
                                a.Body = lVersion[0].VersionData;
                            }
                            else{
                                List<ContentDocument> lDocument = [Select LatestPublishedVersion.VersionData from ContentDocument WHERE latestPublishedVersionId =: contentVersion.Id];
                                a.Body = lDocument[0].LatestPublishedVersion.VersionData;
                            }
                            attaToInsert.add(a);
                        }
                    }else{
                        myChatterComplianceComment.Files_attached_exceeded_size_limit__c = true;
                    }
                    toUpdateCCComments.add(myChatterComplianceComment);
                }
            }
            else{
                ChatterComplianceCommentNew__c myChatterComplianceCommentNew = mapCCNew.get(feedComment.Id);

                ContentVersion contentVersion = contentVersionMap.get(feedComment.RelatedRecordId);
                if (contentVersion == null){
                    contentVersion = getContentVersionFromContentDocument(feedComment, ContentDocumentMap);
                }

                if(contentVersion != null && myChatterComplianceCommentNew != null){

                    myChatterComplianceCommentNew.Files_Attached__c = true;
                    myChatterComplianceCommentNew.Attachment_name__c = contentVersion.title;

                    Attachment a = new Attachment();
                    a.parentId = myChatterComplianceCommentNew.Id;
                    a.Name = contentVersion.title + '.' + contentVersion.filetype.toLowerCase();

                    if(contentVersion.ContentSize < 5242880){
                        if(!chatter.Do_not_keep_any_attachments__c){
                            List<ContentVersion> lVersionFree = [SELECT VersionData FROM ContentVersion WHERE Id = :contentVersion.Id];
                            if(lVersionFree.size() > 0){
                                a.Body = lVersionFree[0].VersionData;
                            }
                            else{
                                List<ContentDocument> lDocumentFree = [Select LatestPublishedVersion.VersionData from ContentDocument WHERE latestPublishedVersionId =: contentVersion.Id];
                                a.Body = lDocumentFree[0].LatestPublishedVersion.VersionData;
                            }
                            attaToInsert.add(a);
                        }
                    }
                    else{
                        myChatterComplianceCommentNew.Files_attached_exceeded_size_limit__c = true;
                    }
                    toUpdateCCCommentsNew.add(myChatterComplianceCommentNew);
                }
            }
            insert attaToInsert;
            attaToInsert.clear();
        }

        if(!chatter.Do_NOT_create_the_chatter_compliance_rec__c || !isTrigger){
            update toUpdateCCComments;
            update toUpdateCCCommentsNew;
        }

        if (isTrigger){
            if(!chatter.Do_NOT_create_the_chatter_compliance_rec__c){
                ChatterCompliance_AdminSettings.sendEmails(toUpdate, items);
                ChatterCompliance_AdminSettings.sendEmails(toUpdateNew, items);
            }else{
                ChatterCompliance_AdminSettings.sendEmails(items);
            }
        }
     }

    /**************************
    ***        DELETE       ***
    **************************/

 public static void DeleteFeedCommentCompliance(list<FeedComment> items, list<Id> itemsId, boolean isTrigger){
    list<Id> tempList = new list<Id>();
    list<ChatterComplianceComment__c> toUpdate = new list<ChatterComplianceComment__c>();
    list<ChatterComplianceCommentNew__c> toUpdateCCCNew = new list<ChatterComplianceCommentNew__c>();
    ArkusChatterComplianceSettings__c chatter = ArkusChatterComplianceSettings__c.getInstance('settings');
    //map<Id,ChatterCompliance__c> ccs = new map<Id,ChatterCompliance__c>();
    map<Id,ChatterComplianceComment__c> comments = new map<Id,ChatterComplianceComment__c>();
    map<Id,ChatterComplianceCommentNew__c> commentsNew = new map<Id,ChatterComplianceCommentNew__c>();

    if(items != null){
        //List<Id> userId = new List<Id>();
        for(FeedComment f : items){
            //userId.add(f.InsertedById);
            tempList.add(f.id);
        }
    }
    else{
        tempList = itemsId;
    }

    //Map<Id, boolean> mapExternalOrFree = ChatterCompliance_AdminSettings.IsChatterExternalOrFreeUser(userId);

    for(ChatterComplianceComment__c ccc : [Select id,Attachment__c,commentId_New__c from ChatterComplianceComment__c where commentId_New__c in : tempList]){
        comments.put(ccc.Attachment__c,ccc);
        comments.put(ccc.commentId_New__c, ccc);
    }

    for(ChatterComplianceCommentNew__c cccn : [Select id,Attachment__c,commentId__c from ChatterComplianceCommentNew__c where commentId__c in : tempList]){
        commentsNew.put(cccn.Attachment__c,cccn);
        commentsNew.put(cccn.commentId__c, cccn);
    }

    for(Id f : tempList){
            ChatterComplianceComment__c item = comments.get(f);
            if(item != null){
                //its standard user
                item.deleted__c = true;
                item.deleted_Date__c = Datetime.now();
                item.deletedBy__c = Userinfo.getUserId();
                toUpdate.add(item);
            }
            else{
                //its free or external user
                ChatterComplianceCommentNew__c itemNew = commentsNew.get(f);
                if(itemNew != null){
                    itemNew.deleted__c = true;
                    itemNew.deleted_Date__c = Datetime.now();
                    itemNew.deletedBy__c = Userinfo.getUserId();
                    toUpdateCCCNew.add(itemNew);
                }
            }
    }

    if(!chatter.Do_NOT_create_the_chatter_compliance_rec__c || !isTrigger){
        upsert toUpdate;
        upsert toUpdateCCCNew;
    }

    /*if(ChatterCompliance_AdminSettings.IsChatterExternalOrFreeUser(UserInfo.getUserId()) == false){
        // For non chatter free users
        for(FeedComment f : items){
            tempList.add(f.id);
        }

        //for(ChatterCompliance__c cc : [Select id,PostId_New__c,Related_record_name__c,PostContent__c from ChatterCompliance__c where PostId_New__c in : tempList]){
        //    ccs.put(cc.PostId_New__c,cc);
        //}

        for(ChatterComplianceComment__c ccc : [Select id,Attachment__c,commentId_New__c from ChatterComplianceComment__c where commentId_New__c in : tempList]){
            comments.put(ccc.Attachment__c,ccc);
            comments.put(ccc.commentId_New__c, ccc);
        }
        for(Id f : tempList){
            ChatterComplianceComment__c item = comments.get(f);
            if(item != null){
                item.deleted__c = true;
                item.deleted_Date__c = Datetime.now();
                item.deletedBy__c = Userinfo.getUserId();
                toUpdate.add(item);
            }
        }
        if(!chatter.Do_NOT_create_the_chatter_compliance_rec__c){
            upsert toUpdate;
        }

    }
    else{
        for(FeedComment f : items){
            tempList.add(f.id);
        }

        for(ChatterCompliance__c cc : [Select id,PostId_New__c,Related_record_name__c,PostContent__c from ChatterCompliance__c where PostId_New__c in : tempList]){
            ccs.put(cc.PostId_New__c,cc);
        }

        for(ChatterComplianceComment__c ccc : [Select id,commentId__c from ChatterComplianceComment__c where commentId__c in : tempList]){
            comments.put(ccc.commentId__c,ccc);
        }

        for(FeedComment f : items){
            ChatterComplianceComment__c item = comments.get(f.id);
            if(item != null){
                item.deleted__c = true;
                item.deleted_Date__c = Datetime.now();
                item.deletedBy__c = Userinfo.getUserId();
                toUpdate.add(item);
            }
        }

        if(!chatter.Do_NOT_create_the_chatter_compliance_rec__c || !isTrigger){
            upsert toUpdate;
        }

    }*/
 }

    private static ContentVersion getContentVersionFromContentDocument(FeedComment f, Map<Id, ContentDocument> ContentDcoumentMap){
        ContentVersion content;
        for(ContentDocument document:ContentDcoumentMap.values()){
            if(document.LatestPublishedVersionId == f.RelatedRecordId){
                content = document.LatestPublishedVersion;
                break;
            }
        }
        return content;
    }
    @future
    public static void deleteScheduleJobFuture(String Id){
        try{
            system.abortJob(id);
        }
        catch(Exception e){

        }
    }

	@future
	public static void createFeedItemComplianceFromTasks(set<Id> tasksId, boolean isInsert){
	try{
		List<Task> taskList = [select id from Task where id IN : tasksId];
		Map<Id,Task> tasksMap = new Map<Id,Task>();
		for(Task t : taskList){
			tasksMap.put(t.id,t);
		}
		List<FeedItem> items = [Select f.Type, f.Title, f.SystemModstamp, f.RelatedRecordId, f.ParentId, f.LinkUrl, f.LikeCount, f.LastModifiedDate, f.IsDeleted, f.InsertedById, f.Id, f.CreatedDate, f.CreatedById, f.ContentType, f.ContentSize, f.ContentFileName, f.ContentDescription, f.ContentData, f.CommentCount, f.Body From FeedItem f where ParentId IN: tasksId];
		List<FeedItem> recordsToChatterCom = new List<FeedItem>();
		for(FeedItem f : items){	
			if(tasksMap.containsKey(f.ParentId)){
				if(tasksMap.get(f.ParentId).Id == f.ParentId){
					system.debug('@@ run logic');
					recordsToChatterCom.add(f);
				}
			}
		}
		if(isInsert){
			ChatterCompliance_Utils.CreateFeedItemCompliance(recordsToChatterCom, true);
		}else{
			ChatterCompliance_Utils.DeleteFeedItemCompliance(trigger.old, null, true);
		}	
	}catch(Exception e){
		system.debug('error: '+ e.getMessage());	
	}
	}	

}