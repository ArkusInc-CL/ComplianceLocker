trigger ChatterCompliance_FeedComment_WordBlocker on FeedComment (before insert) {
    ArkusChatterComplianceSettings__c adminSettings  = ArkusChatterComplianceSettings__c.getInstance('settings');
 
     
     ChatterCompliance_AdminSettings.static_global_map = new Map<string, string>();
     
     List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();


    if (adminSettings != null && adminSettings.Chatter_Compliance_paused__c==false){

        list<ChatterCompliance_Word_blocker__c> wordsNotAllowedList =   new list<ChatterCompliance_Word_blocker__c>();
//      ArkusChatterComplianceSettings__c       adminSettings       =   ArkusChatterComplianceSettings__c.getInstance('settings');

        //Get all the words that are not allowed.
        wordsNotAllowedList=[Select c.Name, c.RecordType.DeveloperName From ChatterCompliance_Word_blocker__c c limit 2000];

        list<ChatterCompliance_PostContentInformation__c> postContentInformationToUpsert = new list<ChatterCompliance_PostContentInformation__c>();


        if (adminSettings!=null){
            
            
            //For every record being inserted.
            for (FeedComment f:trigger.new){
        
                List<string> existingBannedWords = new List<String>();
                Set<string> existingBannedWordsSet = new Set<String>();
                boolean existsBannedWord = false;
        
                 string saveBody = f.CommentBody != null ? f.CommentBody : '';
                string originalBody     =   f.CommentBody != null ? f.CommentBody.toUpperCase() : '';

                //Save the data on PostContentInformation object.
                ChatterCompliance_PostContentInformation__c postContentInformation  =   new ChatterCompliance_PostContentInformation__c();

                postContentInformation.Original_post_content__c   =   saveBody; //originalBody;

                ChatterCompliance_PostContentInformation__c postContentInformationAux  =   new ChatterCompliance_PostContentInformation__c();

            //Check in the list of banned words.
            for(ChatterCompliance_Word_blocker__c c:wordsNotAllowedList){
                //Transform both the comment and the banned word to uppercase to make the comparisson case insensitive.
                String body =   f.CommentBody != null ? f.CommentBody.toUpperCase() : '';
                            
                //If the banned word is found on the comment.
                 if (c.RecordType.DeveloperName == 'RegularExpression'){
                    Matcher m = Pattern.compile(c.Name).matcher(body); // (f.CommentBody);
                    //find all words to be replaced
                    while(!m.hitend() && m.find()){
                        if(!existingBannedWordsSet.contains(m.group().toLowercase())){
                            existingBannedWords.add(m.group());
                            existsBannedWord = true;
                            existingBannedWordsSet.add(m.group().toLowercase());
                        }
                } 
                    if(adminSettings.Substitute_bad_words_for_characters__c   ==  true){

                        //Replace the word on the message with. 
                        f.CommentBody   =   ChatterCompliance_AdminSettings.replaceBannedWordRegExp(f.CommentBody != null ? f.CommentBody : '', c.Name); //body.replaceAll(c.Name.toUpperCase(), '#@()9udsfoiuf3247*%#%@');
                        postContentInformation.Post_content__c    =   f.CommentBody != null ? f.CommentBody : '';
                        postContentInformation.FeedCommentUser__c =   Userinfo.getUserId();

                        postContentInformationAux=postContentInformation;                              

                    }
                
                 }else if (body.contains(c.Name.toUpperCase())){
                    if(adminSettings.Substitute_bad_words_for_characters__c   ==  true){

                        //Replace the word on the message with. 
                        f.CommentBody   =   ChatterCompliance_AdminSettings.replaceBannedWord(f.CommentBody != null ? f.CommentBody : '', c.Name); //body.replaceAll(c.Name.toUpperCase(), '#@()9udsfoiuf3247*%#%@');
                        postContentInformation.Post_content__c    =   f.CommentBody != null ? f.CommentBody : '';
                        postContentInformation.FeedCommentUser__c =   Userinfo.getUserId();

                        postContentInformationAux=postContentInformation;                              

                    }
                    
                    //show an error message
                    existingBannedWords.add(c.Name);
                    existsBannedWord = true;
                
                }else{
                    postContentInformation.Post_content__c        =   f.CommentBody != null ? f.CommentBody : '';
                    postContentInformation.FeedCommentUser__c     =   Userinfo.getUserId();
                 }
            }  
            
            
            if(existsBannedWord){
                // SEND EMAILS:                    
                if(adminSettings.Send_email_if_showing_banned_words__c
                    && adminSettings.ChatterCompliance_Email__c != null
                    && adminSettings.ChatterCompliance_Email__c != ''
                ){
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setBccSender(false);
                    mail.setToAddresses(new List<String>{adminSettings.ChatterCompliance_Email__c});
                    mail.setUseSignature(false); 
                    mail.setSaveAsActivity(false);
                    String msg = 'You are receiving this message because a User has entered a word(s) on Chatter that is included on the banned words list. <br />'
                                 + 'The word(s) is: ';
                    for(String s : existingBannedWords){msg += s + ', ';}
                    msg = msg.substring(0,msg.length() - 2) + '.<br />';
                    msg += 'The name of the user is: ' + Userinfo.getName() + '<br />';
                    if(adminSettings.WordBlocker_ShowAnErrorMessage__c){
                        msg += 'An error was shown to the user and the post was not created.';
                    }else if(adminSettings.Substitute_bad_words_for_characters__c){
                        msg += 'The word(s) was replaced with dummy characters.';
                    }else{
                        msg += 'The post was displayed normally in the Chatter.';
                    }
                    mail.setHtmlBody(msg);
                    mail.setSubject(adminSettings.selectedEmailSubject__c != null ? adminSettings.selectedEmailSubject__c : 'Chatter Compliance word blocker notification');
                    emailsToSend.add(mail);
                }                    
                if(!emailsToSend.isEmpty()){
                    try{
                        Messaging.sendEmail(emailsToSend);
                        emailsToSend.clear();
                    }catch(Exception e){}
                }                
                // ------------
            
                // SHOW ERROR MESSAGE  
                if(adminSettings.WordBlocker_ShowAnErrorMessage__c){
                    if(adminSettings.Message_to_show_on_error__c==null){
                        adminSettings.Message_to_show_on_error__c='';
                    }                        
                    String msg = 'The following word(s) has been blocked: ';
                    for(String s : existingBannedWords){msg += s + ', ';}
                    msg = msg.substring(0,msg.length() - 2);
                    msg += '. ' + adminSettings.Message_to_show_on_error__c;
                    f.addError(msg);
                }
                // ------------------                                                                                      
            }
                            
            try{
                postContentInformationToUpsert.add(postContentInformation);
            }catch(Exception e){
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'We have found an exception:     ' + e);
            }
            
        }


    try{
        if (postContentInformationToUpsert.isEmpty()==false){
            for(Integer i = 0; i < trigger.new.size(); i++){
                Id id1 = trigger.new[i].ParentId;
                Id id2 = trigger.new[i].FeedItemId;
                ChatterCompliance_AdminSettings.static_global_map.put(id1 + '~' + id2 + '~' + '1', postContentInformationToUpsert[i].Original_post_content__c);
            }
        
            if(!adminSettings.Do_NOT_create_the_chatter_compliance_rec__c){
                upsert postContentInformationToUpsert;
            }
            
            for(Integer i = 0; i < trigger.new.size(); i++){
                Id id1 = trigger.new[i].ParentId;
                Id id2 = trigger.new[i].FeedItemId;
                ChatterCompliance_AdminSettings.static_global_map.put(id1 + '~' + id2, postContentInformationToUpsert[i].Id);
            }
        }
    }catch(Exception e){
        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'We have found an exception:     ' + e);
    }
}

    }

}