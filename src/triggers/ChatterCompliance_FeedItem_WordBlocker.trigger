/**
*   Chatter Compliance System (all classes, triggers and pages that start with ChatterCompliance)
*   @author     Arkus Dev Team
*/
trigger ChatterCompliance_FeedItem_WordBlocker on FeedItem (before insert) {
	chatcomp__ArkusChatterComplianceSettings__c       adminSettings       =   chatcomp__ArkusChatterComplianceSettings__c.getInstance('settings');

    ChatterCompliance_AdminSettings.static_global_map2 = new Map<string, string>();
 
    
	if (adminSettings != null && adminSettings.chatcomp__Chatter_Compliance_paused__c==false){

		list<chatcomp__ChatterCompliance_Word_blocker__c> wordsNotAllowedList =   new list<chatcomp__ChatterCompliance_Word_blocker__c>();

		list<String> mailAddresses  =   new list<String>();
		list<chatcomp__ChatterCompliance_PostContentInformation__c> postContentInformationToUpsert = new list<chatcomp__ChatterCompliance_PostContentInformation__c>();

    	//Get all the words that are not allowed.
    	wordsNotAllowedList=[Select c.Name, c.RecordType.DeveloperName From chatcomp__ChatterCompliance_Word_blocker__c c limit 2000];

		if (adminSettings!=null){

        	List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();


        	//For every record being inserted.
        	for (FeedItem f:trigger.new){
           		if (f.Body!=null){
             		final string originalBody   =   f.Body.toUpperCase();

             	    List<string> existingBannedWords = new List<String>();
             	    Set<string> existingBannedWordsSet = new Set<String>();
             		boolean existsBannedWord = false;

              	    //Transform both the comment and the banned word to uppercase to make the comparisson case insensitive.
                	String bodySave = f.Body;
                	String body =   f.Body.toUpperCase();

                	chatcomp__ChatterCompliance_PostContentInformation__c postContentInformationAux  =   new chatcomp__ChatterCompliance_PostContentInformation__c();

                	//Check in the list of banned words.
                	for(chatcomp__ChatterCompliance_Word_blocker__c c:wordsNotAllowedList){
                		if (c.RecordType.DeveloperName == 'RegularExpression'){
                	    	Matcher m = Pattern.compile(c.Name).matcher(f.Body);
                            //find all words to be replaced
                            while(!m.hitend() && m.find()){
                        		if(!existingBannedWordsSet.contains(m.group().toLowercase())){
                 		 			existingBannedWords.add(m.group());
                 					existsBannedWord = true;
                 					existingBannedWordsSet.add(m.group().toLowercase());
                				}
                            }              			
                            if(adminSettings.chatcomp__Substitute_bad_words_for_characters__c==true){

                        	    chatcomp__ChatterCompliance_PostContentInformation__c postContentInformation  =   new chatcomp__ChatterCompliance_PostContentInformation__c();

                                //Apex does pass variables by value, so body will be overriden later. Then we use originalBody to permanently store this data.
                                postContentInformation.chatcomp__Original_post_content__c   =   bodySave; //originalBody;
                                
                                //Replace the word on the message with.
                                f.Body   =   ChatterCompliance_AdminSettings.replaceBannedWordRegExp(f.Body, c.Name); //body.replaceAll(c.Name.toUpperCase(), '#@()9udsfoiuf3247*%#%@');
                                postContentInformation.chatcomp__Post_content__c    =   f.Body;
                                postContentInformation.chatcomp__FeedItemUser__c    =   Userinfo.getUserId();

                    			postContentInformationAux   =   postContentInformation;


                     		}                                                                  
						}
                        //If the banned word is found on the comment.
                        else if (body.contains(c.Name.toUpperCase())){
                            if(adminSettings.chatcomp__Substitute_bad_words_for_characters__c==true){

                        	    chatcomp__ChatterCompliance_PostContentInformation__c postContentInformation  =   new chatcomp__ChatterCompliance_PostContentInformation__c();

                                //Apex does pass variables by value, so body will be overriden later. Then we use originalBody to permanently store this data.
                                postContentInformation.chatcomp__Original_post_content__c   =   bodySave; //originalBody;
                               
                                //Replace the word on the message with.
                                f.Body   =   ChatterCompliance_AdminSettings.replaceBannedWord(f.Body, c.Name); //body.replaceAll(c.Name.toUpperCase(), '#@()9udsfoiuf3247*%#%@');
                                postContentInformation.chatcomp__Post_content__c    =   f.Body;
                                postContentInformation.chatcomp__FeedItemUser__c    =   Userinfo.getUserId();

                    			postContentInformationAux   =   postContentInformation;


                     		}

                                          
                         	//show an error message
                         	existingBannedWords.add(c.Name);
                         	existsBannedWord = true;
                             
						}else{
                        
                        //Save the data on PostContentInformation object.
                        chatcomp__ChatterCompliance_PostContentInformation__c postContentInformation  =   new chatcomp__ChatterCompliance_PostContentInformation__c();

                        postContentInformation.chatcomp__Post_content__c        =   f.body;
                        postContentInformation.chatcomp__FeedItemUser__c        =   Userinfo.getUserId();
                        postContentInformationAux   =   postContentInformation;

            		}
        		}
    
                if(existsBannedWord){
                    // SEND EMAILS:                    
                    if(adminSettings.chatcomp__Send_email_if_showing_banned_words__c
                        && adminSettings.chatcomp__ChatterCompliance_Email__c != null
                        && adminSettings.chatcomp__ChatterCompliance_Email__c != ''
                    ){
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        mail.setBccSender(false);
                        mail.setToAddresses(new List<String>{adminSettings.chatcomp__ChatterCompliance_Email__c});
                        mail.setUseSignature(false); 
                        mail.setSaveAsActivity(false);
                        String msg = 'You are receiving this message because a User has entered a word(s) on Chatter that is included on the banned words list. <br />'
                                     + 'The word(s) is: ';
                        for(String s : existingBannedWords){msg += s + ', ';}
                        msg = msg.substring(0,msg.length() - 2) + '.<br />';
                        msg += 'The name of the user is: ' + Userinfo.getName() + '<br />';
                        if(adminSettings.chatcomp__WordBlocker_ShowAnErrorMessage__c){
                            msg += 'An error was shown to the user and the post was not created.';
                        }else if(adminSettings.chatcomp__Substitute_bad_words_for_characters__c){
                            msg += 'The word(s) was replaced with dummy characters.';
                        }else{
                            msg += 'The post was displayed normally in the Chatter.';
                        }
                        mail.setHtmlBody(msg);
                        mail.setSubject(adminSettings.chatcomp__selectedEmailSubject__c != null ? adminSettings.chatcomp__selectedEmailSubject__c : 'Chatter Compliance word blocker notification');
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
                    if(adminSettings.chatcomp__WordBlocker_ShowAnErrorMessage__c){
                        if(adminSettings.chatcomp__Message_to_show_on_error__c==null){
                            adminSettings.chatcomp__Message_to_show_on_error__c='';
                        }                        
                        String msg = 'The following word(s) has been blocked: ';
                        for(String s : existingBannedWords){msg += s + ', ';}
                        msg = msg.substring(0,msg.length() - 2);
                        msg += '. ' + adminSettings.chatcomp__Message_to_show_on_error__c;
                        f.addError(msg);
                    }
                    // ------------------                                                                      
                }
    
                postContentInformationAux.chatcomp__Original_post_content__c= bodySave; //originalBody;
                
                try{
                    postContentInformationToUpsert.add(postContentInformationAux);
                }
                catch(Exception e){
                    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'We have found an exception:     ' + e);
                }
            }
        }

    
        try{
            if (postContentInformationToUpsert.isEmpty()==false){

                // Save global values to pass them to the next trigger
                for(Integer i = 0; i < trigger.new.size(); i++){
                    Id id1 = trigger.new[i].ParentId;
                    Id id2 = trigger.new[i].InsertedById;
                    ChatterCompliance_AdminSettings.static_global_map2.put(id1 + '~' + id2 + '~' + '1', postContentInformationToUpsert[i].Original_post_content__c);
                }                
            
                if(!adminSettings.chatcomp__Do_NOT_create_the_chatter_compliance_rec__c){
                    upsert postContentInformationToUpsert;
                }
                
                // Save global values to pass them to the next trigger
                for(Integer i = 0; i < trigger.new.size(); i++){
                    Id id1 = trigger.new[i].ParentId;
                    Id id2 = trigger.new[i].InsertedById;
                    ChatterCompliance_AdminSettings.static_global_map2.put(id1 + '~' + id2, postContentInformationToUpsert[i].Id);
                }                
            }
        }catch(Exception e){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'We have found an exception:     ' + e);
        }
}
}
}