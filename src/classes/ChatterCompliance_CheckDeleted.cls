/**
*   Chatter Compliance System (all classes, triggers and pages that start with ChatterCompliance)
*   @author     Arkus Dev Team
*/
global with sharing class ChatterCompliance_CheckDeleted implements Schedulable{
    
    /**
    *   Constructor of the class
    */
    global ChatterCompliance_CheckDeleted(){}

    /**
    *   Batch that executes to delete all the old chatterCompliance records older than the "Time to delete" setting
    */
    global void execute(SchedulableContext sc){
    
        ArkusChatterComplianceSettings__c ccsetting= ArkusChatterComplianceSettings__c.getInstance('settings');
    
        Integer pastDays = Integer.valueOf(ccsetting.Time_to_delete__c);
        if(pastDays < 0){pastDays = 0;}
        Date limitDate = System.today().addDays(pastDays > 0 ? -pastDays : 0);
        
        List<ChatterCompliance__c> ccToDelete = new List<ChatterCompliance__c>();
        List<ChatterComplianceCommentNew__c> cccommentNewToDelete = new List<ChatterComplianceCommentNew__c>();
        List<ChatterComplianceCommentNew__c> cccommentNewToDeleteAux = new List<ChatterComplianceCommentNew__c>();
        List<Id> postContentInfoToDelete = new List<Id>();
        List<Id> postContentInfoToDeleteAux = new List<Id>();
        boolean addToDelete = true;
        
        boolean exitIteration = false;
        
        for(List<ChatterCompliance__c> ccList :
            [SELECT 
                PostContentInformation__c
                , (SELECT Chatter_Compliance_Post_Content_Info__c, LastModifiedDate FROM ChatterComplianceComments__r)
                , (SELECT Chatter_Compliance_Post_Content_Info__c, LastModifiedDate FROM ChatterComplianceCommentsNew__r)
            FROM ChatterCompliance__c
            WHERE LastModifiedDate < :limitDate limit 4000
            ]
        ){
            for(ChatterCompliance__c cc : ccList){
                if(ccToDelete.size() + cccommentNewToDelete.size() + postContentInfoToDelete.size() < 8000){
                    addToDelete = true;
                    
                    postContentInfoToDeleteAux.clear();
                    if(cc.PostContentInformation__c != null){
                        postContentInfoToDeleteAux.add(cc.PostContentInformation__c);
                    }
                    
                    cccommentNewToDeleteAux.clear();
                    for(ChatterComplianceCommentNew__c cccommentNew : cc.ChatterComplianceCommentsNew__r){
                        System.debug('*********cccommentNew.LastModifiedDate: ' + cccommentNew.LastModifiedDate);
                        System.debug('*********limitDate: ' + limitDate);
                        if(cccommentNew.LastModifiedDate >= limitDate){
                            addToDelete = false;
                            cccommentNewToDeleteAux.clear();
                            postContentInfoToDeleteAux.clear();
                            break;
                        }else{
                            cccommentNewToDeleteAux.add(cccommentNew);
                            if(cccommentNew.Chatter_Compliance_Post_Content_Info__c != null){
                                postContentInfoToDeleteAux.add(cccommentNew.Chatter_Compliance_Post_Content_Info__c);
                            }
                        }
                    }
                    
                    if(addToDelete){
                        for(ChatterComplianceComment__c cccomment : cc.ChatterComplianceComments__r){
                            if(cccomment.LastModifiedDate >= limitDate){
                                addToDelete = false;
                                cccommentNewToDeleteAux.clear();
                                postContentInfoToDeleteAux.clear();
                                break;
                            }else{
                                if(cccomment.Chatter_Compliance_Post_Content_Info__c != null){
                                    postContentInfoToDeleteAux.add(cccomment.Chatter_Compliance_Post_Content_Info__c);
                                }                        
                            }
                        }
                    }
                    
                    if(addToDelete){
                        ccToDelete.add(cc);
                        cccommentNewToDelete.addAll(cccommentNewToDeleteAux);
                        postContentInfoToDelete.addAll(postContentInfoToDeleteAux);
                    }
                    
                }else{
                    exitIteration = true;
                    break;
                }
            }
            
            if(exitIteration){break;}
        }
    
        List<ChatterCompliance_PostContentInformation__c> postContentInfo_toDelete =
        [SELECT Id FROM ChatterCompliance_PostContentInformation__c WHERE Id IN :postContentInfoToDelete];

        if(!postContentInfo_toDelete.isEmpty()){
            Database.delete(postContentInfo_toDelete, false);
        }
        if(!cccommentNewToDelete.isEmpty()){
            Database.delete(cccommentNewToDelete, false);
        }
        if(!ccToDelete.isEmpty()){
            Database.delete(ccToDelete, false);
        }
        
    }
    
    
    /**
    *   Code that executes to delete all the old chatterCompliance objects (objects older than the time to delete setting)
    */
/*    global void execute(SchedulableContext sc) {        
        
        if(Schema.sObjectType.ChatterCompliance__c.isUpdateable()){
*/
            
            /*** REPLACED by method ChatterCompliance_AdminSettings.refreshOldCCRecords();
            // This is to switch from the old text field with the Post Id to the new external field
            List<ChatterCompliance__c> toUpdatePostId = [   Select id, PostId__c, PostId_New__c 
                                                            from ChatterCompliance__c where PostId_New__c = null limit 3000 ];
            
            if(!toUpdatePostId.isEmpty()){
                for(ChatterCompliance__c c : toUpdatePostId){
                    c.PostId_New__c = c.PostId__c;
                }
                
                update toUpdatePostId;
            }
            
            // This is to switch from the old text field with the comment Id to the new external field
            List<ChatterComplianceComment__c> toUpdateCommentId = [     Select id, commentId_New__c, commentId__c 
                                                                        from ChatterComplianceComment__c where commentId_New__c = null limit 3000 ];

            if(!toUpdateCommentId.isEmpty()){               
                for(ChatterComplianceComment__c c : toUpdateCommentId){
                    c.commentId_New__c = c.commentId__c;
                }
                
                update toUpdateCommentId;
            }
            ***/

/*            
            //Get all the objects prefixs
            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
            Map<String,String> keyPrefixMap = new Map<String,String>{};
            
            Map<String,Map<id,ChatterCompliance__c>> tables = new Map<String,Map<id,ChatterCompliance__c>>();
            Set<String> keyPrefixSet = gd.keySet();
            List<ChatterCompliance__c> toUpdate = new List<ChatterCompliance__c>();
            List<ChatterComplianceComment__c> toUpdateComments = new List<ChatterComplianceComment__c>();
            
            //Populate the map with the objects prefixes
            for(String sObj : keyPrefixSet){
               Schema.DescribeSObjectResult r = gd.get(sObj).getDescribe();
               String tempName = r.getName();
               String tempPrefix = r.getKeyPrefix();
               keyPrefixMap.put(tempPrefix,tempName);
            } 
            
            //Get the ChatterCompliance__c records that are not deleted and put in the correct list.
            for(ChatterCompliance__c cc :[Select id,Related_record__c,(Select id from ChatterComplianceComments__r) from ChatterCompliance__c where delete__c = false order by createdDate DESC limit 4000]){
                if(cc.related_Record__c != null){
                    String objectType = keyPrefixMap.get(cc.related_Record__c.substring(0,3)); 
                    if(objectType != null){
                        if(tables.get(objectType) == null){
                            Map<Id,ChatterCompliance__c>lst = new Map<Id,ChatterCompliance__c>();
                            lst.put(cc.id,cc);
                            tables.put(objectType,lst);
                        }else{
                            tables.get(objectType).put(cc.id,cc);
                        }
                    }
                }
            }
            
            //Query for the related records to check if are deleted
            for(String table : tables.keySet()){
                Map<Id,ChatterCompliance__c> objs = tables.get(table);
                List<Id> tmpList = new List<Id>();
                for(ChatterCompliance__c c : objs.values()){
                    tmpList.add(c.related_Record__c);
                }
                String query = 'Select id from ' + table + ' where id in : tmpList'; 
                for(sobject so : Database.query(query)){
                    for(ChatterCompliance__c c : objs.values()){
                        if(c.related_Record__c == so.id){
                            objs.remove(c.id);
                        }
                    }
                }
            }
            
            //Mark the chatterCompliance records and its comments as deleted
            for(String table : tables.keySet()){
                for(ChatterCompliance__c c : tables.get(table).values()){
                    c.delete__c= true;
                    c.delete_Date__c = Datetime.now();
                    c.deletedBy__c = Userinfo.getUserId();
                    toUpdate.add(c);
                    for(ChatterComplianceComment__c cc : c.ChatterComplianceComments__r){
                        cc.deleted__c = true;
                        cc.deletedBy__c = Userinfo.getUserId();
                        cc.deleted_Date__c = Datetime.now();
                        toUpdateComments.add(cc);
                    }
                }
            }
            update toUpdate;
            update toUpdateComments;
        }
        
        if(Schema.sObjectType.ChatterCompliance__c.isDeletable()){
            deleteOld();
        }
    }
*/
    
    /**
    *   Deletes all the old chatterCompliance records (records older than the time to delete set)
    */
/*    
    public void deleteOld(){
        List<ChatterCompliance__c> toUpdate = new List<ChatterCompliance__c>();
 //       List<id> feedItemsToDelete = new List<id>();
        List<ChatterComplianceComment__c> toUpdateComments = new List<ChatterComplianceComment__c>();
        ArkusChatterComplianceSettings__c adminSettings = ArkusChatterComplianceSettings__c.getInstance('settings');
        Boolean deleteItem = adminSettings.deleteFeedItem__c;
        
        if(adminSettings != null){
            if(adminSettings.Time_to_delete__c > 0){
                Date tmpDate = Date.today().addDays(-Integer.valueOf(adminSettings.Time_to_delete__c));
                Datetime tmpDT = Datetime.newInstance(tmpDate.year(), tmpDate.month(), tmpDate.day(), 23, 59, 59);
                for(ChatterCompliance__c c :[Select id, PostId__c, PostId_New__c, Related_record__c,(Select id from ChatterComplianceComments__r) from ChatterCompliance__c where createdDate <: tmpDT order by createdDate DESC limit 2000]){
                    toUpdate.add(c);
     //               if(c.Related_record__c != null && c.Related_record__c != ''){feedItemsToDelete.add(c.Related_record__c);}
     //               if(c.PostId_New__c != null && c.PostId_New__c != ''){
     //                 feedItemsToDelete.add(c.PostId_New__c);
     //               }else{
     //                 if(c.PostId__c != null && c.PostId__c != ''){feedItemsToDelete.add(c.PostId__c);}
     //               }
                    for(ChatterComplianceComment__c cc : c.ChatterComplianceComments__r){
                        toUpdateComments.add(cc);
                    }
                }
 //               if((deleteItem) && (Schema.sObjectType.FeedItem.isDeletable())){
 //                   List<FeedItem> toDelete = [Select id from FeedItem where id in:feedItemsToDelete];
 //                   delete toDelete;
  //              }
                delete toUpdateComments;
                delete toUpdate;
                
            }
        }
    }
*/
    
}