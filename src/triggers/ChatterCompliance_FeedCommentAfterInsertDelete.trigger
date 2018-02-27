/**
*   Chatter Compliance System (all classes, triggers and pages that start with ChatterCompliance)
*   @author     Arkus Dev Team
*/
trigger ChatterCompliance_FeedCommentAfterInsertDelete on FeedComment bulk (after delete, after insert) {

    /**
    *   Creates/updates a chatterComplianceComment record when a chatter comment is created/deleted.
    */

    /*
    if(chatcomp__ArkusChatterComplianceSettings__c.getInstance('settings') != null){
        if(!chatcomp__ArkusChatterComplianceSettings__c.getInstance('settings').chatcomp__Chatter_Compliance_paused__c){

            chatcomp__ArkusChatterComplianceSettings__c chatter = chatcomp__ArkusChatterComplianceSettings__c.getInstance('settings');

            list<Attachment> attaToInsert = new list<Attachment>();
            list<Id> attachments = new list<Id>();
            boolean doNotkeepAttachments = chatcomp__ArkusChatterComplianceSettings__c.getInstance('settings').chatcomp__Do_not_keep_any_attachments__c;
            map<ID,ContentVersion> contentVersionMap = new map<Id,ContentVersion>();
            map<ID,ContentDocument> contentDocumentMap = new map<Id,ContentDocument>();

            List<Id> relatedRecordIds = new List<Id>();
            if(trigger.isInsert){
                for(FeedComment fc : trigger.new){
                    relatedRecordIds.add(fc.RelatedRecordId);
                }
            }

            for (ContentVersion contentVersion:[select title, filetype, Id, contentSize from ContentVersion WHERE Id IN :relatedRecordIds]){
                contentVersionMap.put(contentVersion.id,contentVersion);
            }

            for (ContentDocument contentDocument:[SELECT LatestPublishedVersionId, LatestPublishedVersion.Title, LatestPublishedVersion.ContentSize FROM ContentDocument WHERE LatestPublishedVersionId IN: relatedRecordIds]){
                contentDocumentMap.put(contentDocument.id,contentDocument);
            }

            ChatterCompliance_AdminSettings.refreshOldCCRecords();

            //if(Schema.sObjectType.ChatterComplianceComment__c.isUpdateable()){
            if(ChatterCompliance_AdminSettings.IsChatterExternalOrFreeUser(UserInfo.getUserId()) == false){
                // For non chatter free users
                List<ChatterComplianceComment__c> toUpdate = new List<ChatterComplianceComment__c>();

                Map<Id,ChatterCompliance__c> ccs = new Map<Id,ChatterCompliance__c>();
                Map<Id,ChatterComplianceComment__c> comments = new Map<Id,ChatterComplianceComment__c>();
                List<Id> tempList = new List<Id>();

                if(trigger.isInsert){
                    for(FeedComment f : trigger.new){
                        tempList.add(f.Id);
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

                for(ChatterComplianceComment__c ccc : [Select id,chatcomp__Attachment__c,commentId_New__c from ChatterComplianceComment__c where commentId_New__c in : tempList]){
                    comments.put(ccc.chatcomp__Attachment__c,ccc);
                    comments.put(ccc.commentId_New__c, ccc);
                }

                if(trigger.isInsert){
                    list<ID> attachmentIds = new list<ID>();
                    for(FeedComment f : trigger.new){
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
                                    cc.chatcomp__Chatter_Compliance_Post_Content_Info__c = ChatterCompliance_AdminSettings.static_global_map.get(id1 + '~' + id2);
                                }
                                if(ChatterCompliance_AdminSettings.static_global_map.get(id1 + '~' + id2 + '~' + '1') != null){
                                    cc.chatcomp__Original_comment_content__c = ChatterCompliance_AdminSettings.static_global_map.get(id1 + '~' + id2 + '~' + '1');
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
                    if(!chatter.chatcomp__Do_NOT_create_the_chatter_compliance_rec__c){
                        insert toUpdate;
                    }

                    List<ChatterCompliance__c> toUpdateExceededLimit = new List<ChatterCompliance__c>();


                      if((attaToInsert != null) && (attaToInsert.size() > 0)){

                          if(!chatter.chatcomp__Do_NOT_create_the_chatter_compliance_rec__c){
                              insert attaToInsert;
                          }
                          attaToInsert.clear();
                      }

                      if((toUpdateExceededLimit != null) && (toUpdateExceededLimit.size() > 0)){
                        if(!chatter.chatcomp__Do_NOT_create_the_chatter_compliance_rec__c){
                            update toUpdateExceededLimit;
                        }
                        toUpdateExceededLimit.clear();
                      }


                    chatcomp__ChatterComplianceComment__c myChatterComplianceComment = new chatcomp__ChatterComplianceComment__c();

                    for(FeedComment feedComment : trigger.new){

                        try{
                            ContentVersion contentVersion = contentVersionMap.get(feedComment.RelatedRecordId);
                            if(contentVersion == null){
                                contentVersion = getContentVersionFromContentDocument(feedComment, ContentDocumentMap);
                            }

                             if(contentVersion != null && contentVersion.ContentSize > 5242880){
                                myChatterComplianceComment.chatcomp__Files_attached_exceeded_size_limit__c = true;
                             }

                            Attachment a = new Attachment();

                            for (ChatterComplianceComment__c chatterComplianceComment : toUpdate){
                                if (chatterComplianceComment.chatcomp__commentId_New__c == feedComment.Id){
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
                                    if(!chatter.chatcomp__Do_not_keep_any_attachments__c){
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
                                    myChatterComplianceComment.chatcomp__Files_attached_exceeded_size_limit__c = true;
                                }
                            }


                        }catch(Exception e){

                        }

                    }

                    try{
                        if(!chatter.chatcomp__Do_NOT_create_the_chatter_compliance_rec__c){
                            update myChatterComplianceComment;
                            insert attaToInsert;
                        }
                    }catch(exception e){}
                    try{
                        if(!chatter.chatcomp__Do_NOT_create_the_chatter_compliance_rec__c){
                            ChatterCompliance_AdminSettings.sendEmails(toUpdate);
                        }else{
                            ChatterCompliance_AdminSettings.sendEmails(trigger.new);
                        }
                    }catch(exception e){}

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
                    if(!chatter.chatcomp__Do_NOT_create_the_chatter_compliance_rec__c){
                        upsert toUpdate;
                    }
                }
            }else{
                // For Chatter Free Users
                List<ChatterComplianceCommentNew__c> toUpdate = new List<ChatterComplianceCommentNew__c>();

                Map<Id,ChatterCompliance__c> ccs = new Map<Id,ChatterCompliance__c>();
                Map<Id,ChatterComplianceCommentNew__c> comments = new Map<Id,ChatterComplianceCommentNew__c>();
                List<Id> tempList = new List<Id>();

                if(chatcomp__ArkusChatterComplianceSettings__c.getInstance('settings') != null){
                    String owner = chatcomp__ArkusChatterComplianceSettings__c.getInstance('settings').ChatterCompliance_owner__c;
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

                                Id id1 = f.ParentId;
                                Id id2 = f.FeedItemId;
                                if(ChatterCompliance_AdminSettings.static_global_map != null){
                                    if(ChatterCompliance_AdminSettings.static_global_map.get(id1 + '~' + id2) != null){
                                        cc.chatcomp__Chatter_Compliance_Post_Content_Info__c = ChatterCompliance_AdminSettings.static_global_map.get(id1 + '~' + id2);
                                    }
                                    if(ChatterCompliance_AdminSettings.static_global_map.get(id1 + '~' + id2 + '~' + '1') != null){
                                        cc.chatcomp__Original_comment_content__c = ChatterCompliance_AdminSettings.static_global_map.get(id1 + '~' + id2 + '~' + '1');
                                    }
                                }

                                toUpdate.add(cc);
                            }
                        }

                        if(!chatter.chatcomp__Do_NOT_create_the_chatter_compliance_rec__c){
                            insert toUpdate;
                        }

                        chatcomp__ChatterComplianceCommentNew__c myChatterComplianceCommentNew;
                        List<chatcomp__ChatterComplianceCommentNew__c> toUpdateCCCommentsNew = new List<chatcomp__ChatterComplianceCommentNew__c>();

                        for(FeedComment feedComment : trigger.new){

                            myChatterComplianceCommentNew = null;

                            for (ChatterComplianceCommentNew__c cccNew : toUpdate){
                                if (cccNew.chatcomp__commentId__c == feedComment.Id){
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
                                    if(!chatter.chatcomp__Do_not_keep_any_attachments__c){
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
                                }else{
                                    myChatterComplianceCommentNew.chatcomp__Files_attached_exceeded_size_limit__c = true;
                                }

                                toUpdateCCCommentsNew.add(myChatterComplianceCommentNew);
                            }

                         }

                        if(!chatter.chatcomp__Do_NOT_create_the_chatter_compliance_rec__c){
                            upsert toUpdateCCCommentsNew;
                            upsert attaToInsert;
                        }

                        try{
                            if(!chatter.chatcomp__Do_NOT_create_the_chatter_compliance_rec__c){
                                ChatterCompliance_AdminSettings.sendEmails(toUpdate);
                            }else{
                                ChatterCompliance_AdminSettings.sendEmails(trigger.new);
                            }
                        }catch(exception e){}
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
                        if(!chatter.chatcomp__Do_NOT_create_the_chatter_compliance_rec__c){
                            upsert toUpdate;
                        }
                    }
                }
            }


        }
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

    */
    if(chatcomp__ArkusChatterComplianceSettings__c.getInstance('settings') != null){
    	if(!chatcomp__ArkusChatterComplianceSettings__c.getInstance('settings').chatcomp__Chatter_Compliance_paused__c){

		    if (trigger.isInsert){
		    	//ChatterCompliance_Utils.CreateFeedCommentCompliance(trigger.new, true);
		    	ChatterCompliance_Utils.CreateFeedCommentComplianceNew(trigger.new, true);
		    }else if(trigger.isDelete){
		    	ChatterCompliance_Utils.DeleteFeedCommentCompliance(trigger.old, null, true);
		    }
    	}
    }

}