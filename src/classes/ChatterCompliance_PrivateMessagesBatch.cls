/**
*   Chatter Compliance System (all classes, triggers and pages that start with ChatterCompliance)
*   @author     Arkus Dev Team
*
*   Transform all Chatter Private Messages into Chatter Compliance records
*/
global with sharing class ChatterCompliance_PrivateMessagesBatch implements Database.Batchable<sObject>, Database.Stateful {

    private SObject currentParentChatterMessage = null;
    
    global ChatterCompliance_PrivateMessagesBatch(){}


    global Database.QueryLocator start(Database.BatchableContext BC){
        Date d = system.today().addDays(-2000);
        
        ArkusChatterComplianceSettings__c adminSettings =
            ArkusChatterComplianceSettings__c.getInstance('settings');
        if(adminSettings != null){
            if(adminSettings.Scheduled_Job_Id__c != null && adminSettings.Scheduled_Job_Id__c != ''){
                Integer daysPast = 2000;
                try{
                    daysPast = Integer.valueOf(adminSettings.Time_to_delete__c);
                }catch(Exception e){daysPast = 2000;}
                d = system.today().addDays(-daysPast);
            }
        }
    	try{
        	return Database.getQueryLocator(
            	'SELECT Body, SentDate, ConversationId, SenderId FROM ChatterMessage WHERE SentDate >= :d ORDER BY ConversationId, SentDate ASC'
        	);
    	}catch(Exception e){
    		return Database.getQueryLocator('SELECT Id FROM User where Id = null');
    	}
    }


    global void execute(Database.BatchableContext BC, List<sObject> batch){
        if(batch.size() == 0){
            return;
        }
        List<SObject> cms = (List<SObject>)batch;
        
        if(currentParentChatterMessage == null){
            this.currentParentChatterMessage = cms[0];
        }

        List<Id> cmsIds = new List<Id>();
        List<Id> cmsSenderIds = new List<Id>();
        for(SObject cm : cms){
            cmsIds.add(cm.Id);
            cmsSenderIds.add((Id)cm.get('SenderId'));
        }
        
        // Find Users License:
        Map<Id, User> map_id_user = new Map<Id, User>(
            [SELECT Name, Profile.UserLicense.Name FROM User WHERE Id IN :cmsSenderIds]
        ); 
        // -------------------
        
        // Create Map with parent message and all children messages in the same conversation:
        Map<SObject, List<SObject>> map_parentMsg_childMsgs = new Map<SObject, List<SObject>>();
        map_parentMsg_childMsgs.put(this.currentParentChatterMessage, new List<SObject>());
        for(SOBject cm : cms){
            if((Id)cm.get('ConversationId') != (Id)this.currentParentChatterMessage.get('ConversationId')){
                // New Parent Message found:                
                this.currentParentChatterMessage = cm;
                map_parentMsg_childMsgs.put(this.currentParentChatterMessage, new List<SOBject>());
            }else{
                // Add a child message to its parent message:
                if(cm != this.currentParentChatterMessage){
                    map_parentMsg_childMsgs.get(this.currentParentChatterMessage).add(cm);
                }
            }
        }
        List<Id> cmParent_ids = new List<Id>();
        for(SOBject cm : map_parentMsg_childMsgs.keySet()){
            cmParent_ids.add(cm.Id);
        }
        // Bring all Compliance records for each parent Messages:
        Map<Id, Set<Id>> map_cmsgId_cmsgIds = new Map<Id, Set<Id>>();
        Map<Id, Id> map_cmsgId_ccId = new Map<Id, Id>(); // map of children id and parent id
        for(ChatterCompliance__c cc : 
            [SELECT PostId_New__c, PostId__c
            , (SELECT commentId__c, commentId_New__c FROM ChatterComplianceComments__r)
            FROM ChatterCompliance__c WHERE PostId_New__c IN :cmParent_ids OR PostId__c IN :cmParent_ids]){
            Id idAux = null;
            if(cc.PostId_New__c != null && cc.PostId_New__c != ''){
                map_cmsgId_cmsgIds.put(cc.PostId_New__c, new Set<Id>());
                map_cmsgId_ccId.put(cc.PostId_New__c, cc.Id);
                idAux = cc.PostId_New__c;
            }else if(cc.PostId__c != null && cc.PostId__c != ''){
                map_cmsgId_cmsgIds.put(cc.PostId__c, new Set<Id>());
                map_cmsgId_ccId.put(cc.PostId__c, cc.Id);
                idAux = cc.PostId__c;
            }
            if(idAux != null){
                // Add children Ids:
                for(ChatterComplianceComment__c ccc : cc.ChatterComplianceComments__r){
                    if(ccc.commentId_New__c != null && ccc.commentId_New__c != ''){
                        map_cmsgId_cmsgIds.get(idAux).add(ccc.commentId_New__c);
                        map_cmsgId_ccId.put(ccc.commentId_New__c, cc.Id);
                    }else if(ccc.commentId__c != null && ccc.commentId__c != ''){
                        map_cmsgId_cmsgIds.get(idAux).add(ccc.commentId__c);
                        map_cmsgId_ccId.put(ccc.commentId__c, cc.Id);
                    }
                    
                }
            }
        }
        // ----------

        // Insert parents Chatter Compliance records if they don't exist already:
        List<ChatterCompliance__c> ccListToInsert = new List<ChatterCompliance__c>();
        Map<Id, ChatterCompliance__c> map_cmsgId_cc = new Map<Id, ChatterCompliance__c>();
        for(SObject cm : map_parentMsg_childMsgs.keySet()){
            if(map_cmsgId_cmsgIds.get(cm.Id) == null){// if it doesn't exist, then insert it:
                ChatterCompliance__c cc = new ChatterCompliance__c();
            
                if(map_id_user.get((Id)cm.get('SenderId')) != null &&
                    (
                    map_id_user.get((Id)cm.get('SenderId')).Profile.UserLicense.Name == 'Chatter External'
                    )
                ){
                    cc.Post_made_by_an_outside_contact__c = true;
                }else{
                    cc.Post_made_by_an_outside_contact__c = false;
                }
                cc.OriginalPostContent__c = (String)cm.get('Body');
                cc.PostContent__c = (String)cm.get('Body');
                cc.This_message_is_a_ChatterMessage__c = true;
                cc.Post_Created_Date__c = (Datetime)cm.get('SentDate');
                cc.User__c = (Id)cm.get('SenderId');
                cc.PostId_New__c = cm.Id;
                cc.PostId__c = cm.Id;
                cc.Related_record__c = (Id)cm.get('SenderId');
                cc.Related_record_name__c = map_id_user.get((Id)cm.get('SenderId')) != null ? map_id_user.get((Id)cm.get('SenderId')).Name : '';
            
                ccListToInsert.add(cc);
                map_cmsgId_cc.put(cm.Id, cc);
            }
        }
        if(!ccListToInsert.isEmpty()){
            upsert ccListToInsert;
        }        
        // ------------

        // Insert children Chatter Compliance Comment records if they don't exist already:
        List<ChatterComplianceComment__c> cccListToInsert = new List<ChatterComplianceComment__c>();
        for(SObject cm : map_parentMsg_childMsgs.keySet()){
            for(SObject cm2 : map_parentMsg_childMsgs.get(cm)){
                // if it doesn't exist, then insert it:
                if(map_cmsgId_cmsgIds.get(cm.Id) == null || map_cmsgId_cmsgIds.get(cm.Id).contains(cm2.Id) == false){
                    ChatterComplianceComment__c ccc = new ChatterComplianceComment__c();

                    if(map_cmsgId_ccId.get(cm.Id) != null){
                        ccc.ChatterCompliance__c = map_cmsgId_ccId.get(cm.Id);
                    }else{
                        ccc.ChatterCompliance__c = map_cmsgId_cc.get(cm.Id).Id;
                    }
               
                
                    if(map_id_user.get((Id)cm2.get('SenderId')) != null &&
                        (
                        map_id_user.get((Id)cm2.get('SenderId')).Profile.UserLicense.Name == 'Chatter External'
                        )
                    ){
                        ccc.Post_made_by_an_outside_contact__c = true;
                    }else{
                        ccc.Post_made_by_an_outside_contact__c = false;
                    }
                    ccc.Original_Comment_Content__c = (String)cm2.get('Body');
                    ccc.CommentContent__c = (String)cm2.get('Body');
                    ccc.This_message_is_a_ChatterMessage__c = true;
                    ccc.CommentId_New__c = cm2.Id;
                    ccc.CommentId__c = cm2.Id;
                    ccc.MessageSender__c = (Id)cm2.get('SenderId');
                
                    cccListToInsert.add(ccc);
                    
                }
            }
        }
        if(!cccListToInsert.isEmpty()){
            insert cccListToInsert;
        }
        // ------------
        

   }


    global void finish(Database.BatchableContext BC){


    }


}