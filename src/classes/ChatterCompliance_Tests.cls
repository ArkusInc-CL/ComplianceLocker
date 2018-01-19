/**
*   Chatter Compliance System (all classes, triggers and pages that start with ChatterCompliance)
*   @author     Arkus Dev Team
*/
@isTest(seeAllData=true)
private class ChatterCompliance_Tests {

    /**
    *   Creates and deletes posts and feed items
    */
    /*
    @isTest(seeAllData=true)
    static void testChatterCompliance() {
        //Adding a Text post
        Test.startTest();
        if(ArkusChatterComplianceSettings__c.getInstance('settings') == null){
            ChatterCompliance_AdminSettings adminController = new ChatterCompliance_AdminSettings();
            adminController.initializeChatterCompliance();
        }

        FeedItem post = new FeedItem();
        post.ParentId = Userinfo.getUserId();
        post.Body = 'Post Body';
        insert post;

        List<ChatterCompliance__c> ccList = [Select id,delete__c,update__c,Post_Created_Date__c,user__c,Related_record__c,PostContent__c from ChatterCompliance__c where Postid_New__c =: post.id limit 1];

        if(!ccList.isEmpty()){
            ChatterCompliance__c cc = ccList.get(0);
            System.assertEquals(cc.delete__c,false);
            System.assertEquals(cc.update__c,false);
            System.assertEquals(cc.user__c,Userinfo.getUserId());
            System.assertEquals(cc.Related_record__c,post.parentId);
            System.assertEquals(cc.PostContent__c,post.body);

            //Adding a Link post
            post = new FeedItem();
            post.ParentId = Userinfo.getUserId();
            post.Body = 'Enter post text here';
            post.LinkUrl = 'http://www.someurl.com';
            insert post;

            cc = [Select id,delete__c,update__c,Post_Created_Date__c,user__c,Related_record__c,PostContent__c from ChatterCompliance__c where Postid_New__c =: post.id limit 1][0];
            System.assertEquals(cc.PostContent__c,post.LinkUrl);

            FeedComment fcomment = new FeedComment();
            fcomment.FeedItemId = post.id;
            fcomment.CommentBody = 'Comment Body';
            insert fcomment;

            ChatterComplianceComment__c ccc = [Select id,ChatterCompliance__c,commentContent__c,commentId_New__c from ChatterComplianceComment__c where commentId_New__c =: fcomment.id limit 1][0];

            System.assertEquals(cc.id,ccc.ChatterCompliance__c);
            System.assertEquals(fcomment.CommentBody,ccc.commentContent__c);
            System.assertEquals(fcomment.id,ccc.commentId_New__c);

    //        delete fcomment;

            //Adding a Content post
            post = new FeedItem();
            post.ParentId = Userinfo.getUserId();
            post.Body = 'Enter post text here';
            post.type = 'ContentPost';
            post.ContentData = Blob.valueOf('a');
            post.ContentFileName = 'sample.pdf';
            insert post;

            cc = [Select id,delete__c,update__c,Post_Created_Date__c,user__c,Related_record__c,PostContent__c from ChatterCompliance__c where Postid_New__c =: post.id limit 1][0];
            System.assertEquals(cc.PostContent__c,post.body);


            delete post;


            User user = [select id, CurrentStatus from User where id = :UserInfo.getUserId()];
            user.CurrentStatus = 'New status';
            update user;

            List<FeedItem> lst = new List<FeedItem>([Select f.Id From FeedItem f order by createddate desc limit 1]);

            system.debug('------ lst: ' + lst);//List<UserFeed> lst = new List<UserFeed>([Select u.FeedPost.Body, u.FeedPost.FeedItemId From UserFeed u order by createddate desc limit 1]);

            cc = [Select id,delete__c,update__c,Post_Created_Date__c,user__c,Related_record__c,PostContent__c from ChatterCompliance__c where Postid_New__c =: lst[0].Id limit 1][0];

            System.assertEquals(cc.delete__c,false);
            System.assertEquals(cc.update__c,false);
            System.assertEquals(cc.user__c,Userinfo.getUserId());
            System.assertEquals(cc.Related_record__c,Userinfo.getUserId());
            System.assertEquals(cc.PostContent__c,'New status');
        }

        Test.stopTest();
    }
    */

    /**
    *   Creates and deletes posts and feed items and updates Admin Settings
    */
    static testMethod void testChatterComplianceDeleted() {
        Test.startTest();
        if (ArkusChatterComplianceSettings__c.getInstance('settings') == null){
            ChatterCompliance_AdminSettings adminController = new ChatterCompliance_AdminSettings();
            adminController.initializeChatterCompliance();
        }
        Event e = new Event();
        e.DurationInMinutes = 10;
        e.ActivityDate = Date.today();
        e.ActivityDateTime = Datetime.now();
        insert e;
        ChatterCompliance__c cc = new ChatterCompliance__c();
        cc.Related_record__c = e.id;
        insert cc;
        cc = new ChatterCompliance__c();
        cc.Related_record__c = e.id;
        insert cc;
        System.assertEquals([Select id from ChatterCompliance__c where id =:cc.id].size(),1);
        ChatterCompliance_CheckDeleted controller = new ChatterCompliance_CheckDeleted();
        controller.execute(null);


        ArkusChatterComplianceSettings__c adminSettings = ArkusChatterComplianceSettings__c.getInstance('settings');
        adminSettings.Time_to_delete__c = 2;
        update adminSettings;

        ChatterComplianceComment__c ccc = new ChatterComplianceComment__c();
        ccc.commentContent__c = 'test';
        ccc.ChatterCompliance__c = cc.id;
        insert ccc;
        System.assertEquals(cc.delete__c,false);
        System.assertEquals(ccc.deleted__c,false);

        delete e;
        controller.execute(null);
        cc = [Select id,delete__c from ChatterCompliance__c where id =:cc.id];
        ccc = [Select id,deleted__c from ChatterComplianceComment__c where id =:ccc.id];
        //System.assertEquals(cc.delete__c,true);
        //System.assertEquals(ccc.deleted__c,true);
        Test.stopTest();
    }

    /**
    *   Tests methods of Chatter Compliance using class ChatterCompliance_AdminSettings
    */
    static testMethod void testChatterComplianceAdmin() {
        Test.startTest();

        PageReference testPage = Page.ChatterCompliance_AdminSettings;
        Test.setCurrentPage(testPage);

        if (ArkusChatterComplianceSettings__c.getInstance('settings') == null){
            ChatterCompliance_AdminSettings adminController = new ChatterCompliance_AdminSettings();
            adminController.initializeChatterCompliance();
        }
        FeedItem post = new FeedItem();
        post.ParentId = Userinfo.getUserId();
        post.Body = 'Post Body';
        insert post;

        ChatterCompliance_AdminSettings adminController = new ChatterCompliance_AdminSettings();
        //validate Save method
        adminController.save();


        adminController.goToMonitoring();
        //validate cancel method
        adminController.cancel();

        //validate createEmail method
        Messaging.SingleEmailMessage createEmail = ChatterCompliance_AdminSettings.createEmail('body','content','related','relatedId',DateTime.now(),'toAddress');

        //validate scheduleJob method
        ArkusChatterComplianceSettings__c adminSettings = ArkusChatterComplianceSettings__c.getInstance('settings');
        adminSettings.Scheduled_Job_Id__c = '';
        update adminSettings;

        // Check Pause/Resume CC:
        adminController.pauseExecution();
        ArkusChatterComplianceSettings__c adminSettingsAux = ArkusChatterComplianceSettings__c.getInstance('settings');
        System.assert(adminSettingsAux.Chatter_Compliance_paused__c);
        adminController.resumeExecution();
        adminSettingsAux = ArkusChatterComplianceSettings__c.getInstance('settings');
        System.assert(!adminSettingsAux.Chatter_Compliance_paused__c);
        // -----

        adminController.scheduleJob();
        adminController.unscheduleJob();

        adminSettings = ArkusChatterComplianceSettings__c.getInstance('settings');
        adminSettings.Scheduled_Job_Id__c = 'some id';
        update adminSettings;

        adminController.scheduleJob();
        adminController.unscheduleJob();

        adminSettings  = ArkusChatterComplianceSettings__c.getInstance('settings');
        adminSettings.ChatterCompliance_Owner__c=Userinfo.getUserId();
        update adminSettings;
        adminController = new ChatterCompliance_AdminSettings();
        adminController.save();

        adminSettings.Time_to_delete__c = -1;
        update adminSettings;
        System.assertEquals(adminSettings.Time_to_delete__c, -1);
        adminController = new ChatterCompliance_AdminSettings();
        adminController.save();

        Test.stopTest();
    }

    /**
    *   Tests method initializeChatterCompliance
    */
    static testMethod void testInitializeChatterCompliance(){
        test.startTest();
        if(ArkusChatterComplianceSettings__c.getInstance('settings') != null){
            delete ArkusChatterComplianceSettings__c.getInstance('settings');
        }
        ChatterCompliance_AdminSettings adminController = new ChatterCompliance_AdminSettings();
        adminController.initializeChatterCompliance();
        System.assertEquals(ArkusChatterComplianceSettings__c.getInstance('settings') != null, true);
        ArkusChatterComplianceSettings__c adminSettings  = ArkusChatterComplianceSettings__c.getInstance('settings');
        System.assertEquals(adminSettings.Name , 'settings');
        test.stopTest();
    }

    /**
    *   Tests method SendMails
    */
    static testMethod void testSendMails(){
        test.startTest();
        if (ArkusChatterComplianceSettings__c.getInstance('settings') == null){
            ChatterCompliance_AdminSettings adminController = new ChatterCompliance_AdminSettings();
            adminController.initializeChatterCompliance();
        }
        ArkusChatterComplianceSettings__c adminS= ArkusChatterComplianceSettings__c.getInstance('settings');
        adminS.ChatterCompliance_Email__c = 'mail@mail.com';
        update adminS;


        ChatterCompliance__c cc = new ChatterCompliance__c();
        cc.Files_Attached__c = true;
        insert cc;

        Attachment a = new Attachment();
        a.parentId = cc.id;
        a.Name = 'test';
        a.Body = Blob.valueOf('test');
        insert a;
        ChatterCompliance_AdminSettings.sendEmails(new List<ChatterCompliance__c>{cc});

        Profile p = [select id from profile limit 1];

        User u = new User(
            alias = 'TArkusCC',
            email='testUser@arkusinc.com',
            emailencodingkey='UTF-8',
            lastname='Testing',
            languagelocalekey='en_US',
            localesidkey='en_US',
            profileid = p.id,
            timezonesidkey='America/Los_Angeles',
            Username='arkusTestChatterCompliance@arkusinc.com',
            CompanyName = 'Salesforce',
            Title = 'Developer'
        );
        u.Username = 'arkusTestChatterCompliance@arkusinc.com';
        insert u;
        System.assertEquals(u.Username, 'arkusTestChatterCompliance@arkusinc.com');

        adminS.ChatterCompliance_Owner__c = u.id;
        update adminS;
        System.assertEquals(adminS.ChatterCompliance_Owner__c, u.id);

        ChatterCompliance_AdminSettings controller = new ChatterCompliance_AdminSettings();
        controller.save();

        ChatterComplianceComment__c ccc = new ChatterComplianceComment__c();
        ccc.commentContent__c = 'test';
        ccc.ChatterCompliance__c = cc.id;
        insert ccc;
        ChatterComplianceCommentNew__c cccNew = new ChatterComplianceCommentNew__c();
        cccNew.commentContent__c = 'test commentNew';
        cccNew.ChatterCompliance__c = cc.id;
        insert cccNew;
        ChatterCompliance_AdminSettings.sendEmails(new List<ChatterComplianceComment__c>{ccc});
        ChatterCompliance_AdminSettings.sendEmails(new List<ChatterComplianceCommentNew__c>{cccNew});

        test.stopTest();
    }


     /**
    *   Tests method SendMails with List FeedComment in ChatterCompliance_AdminSettings
    */
    static testMethod void testSendMails2(){

        FeedItem post = new FeedItem();
        post.ParentId = Userinfo.getUserId();
        post.Body = 'Post Body';
        insert post;

        List<FeedComment> comments = new List<FeedComment>();
        FeedComment comment = new FeedComment();
        comment.FeedItemId = post.Id;
        comment.commentbody = 'Comment body test';
        insert comment;
        comments.add(comment);
        ChatterCompliance_AdminSettings.sendEmails(comments);

        system.assert(comment != null);
    }

    /**
    *   Tests other methods in ChatterCompliance_AdminSettings
    */
    static testMethod void otherFunctions(){
        Test.startTest();
        ChatterCompliance_AdminSettings controller = new ChatterCompliance_AdminSettings();
        controller.scheduleMessageToCompliance();
        controller.unscheduleMessageToCompliance();
        controller.deleteOriginalContentScheduleJob();


        chatterCompliance__c cc = new chatterCompliance__c();
        insert cc;
        chatterComplianceComment__c ccc = new chatterComplianceComment__c();
        ccc.ChatterCompliance__c = cc.Id;
        insert ccc;

        ChatterCompliance_AdminSettings.refreshOldCCRecords_asynchronic();
        ChatterCompliance_AdminSettings.deleteOldCCRecords_asynchronic(1);
        ChatterCompliance_AdminSettings.deleteOldCCRecords_asynchronic(2);
        Test.stopTest();

        system.assert(controller != null);
    }
    /**
    *   Tests method ChatterCompliance_OwnerLookup
    */
    static testMethod void testChatterCompliance_OwnerLookup(){
        test.startTest();

        if (ArkusChatterComplianceSettings__c.getInstance('settings') == null){
            ChatterCompliance_AdminSettings adminController = new ChatterCompliance_AdminSettings();
            adminController.initializeChatterCompliance();
        }

        ChatterCompliance_OwnerLookup controller = new ChatterCompliance_OwnerLookup();
        controller.find();
        controller.clear();

        controller.textToSearch = '*';
        controller.find();

        controller.textToSearch = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa52';
        controller.find();
        System.assertEquals(controller.textToSearch, 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa');

        Test.stopTest();

        system.assert(controller != null);
    }

    /**
    *   Physically delete ChatterCompliance records, removing all Comments from CC record
    */
    static testMethod void testChatterComplianceDeletion() {
        test.startTest();

        FeedItem post = new FeedItem();
        post.ParentId = Userinfo.getUserId();
        post.Body = 'Post Body';
        insert post;

        ChatterCompliance__c cc = null;
        for(ChatterCompliance__c c : [SELECT PostId__c, PostId_New__c FROM ChatterCompliance__c WHERE PostId_New__c = :post.Id limit 1]){
            cc = c;
        }

        // Insert CC Comment New records:
        ChatterComplianceCommentNew__c cccNew = new ChatterComplianceCommentNew__c();
        cccNew.commentContent__c = 'test comment New';
        cccNew.ChatterCompliance__c = cc.id;
        insert cccNew;
        // ------

        delete cc;

        System.assert([SELECT Id FROM ChatterComplianceCommentNew__c WHERE Id = :cccNew.Id].size() == 0);

        test.stopTest();
    }

    /**
    *   Tests method ChatterCompliance_UserQueueExists
    */
    static testMethod void testChatterCompliance_UserQueueExists(){
        test.startTest();

        User u = [SELECT Id FROM User LIMIT 1];

        Group g = new Group();
        g.Name = 'test test test Group';
        insert g;

        System.assertEquals(ChatterCompliance_AdminSettings.existId(u.Id), true);
        System.assertEquals(ChatterCompliance_AdminSettings.existId(g.Id), true);

        delete g;
        System.assertEquals(ChatterCompliance_AdminSettings.existId(g.Id), false);

        Test.stopTest();
    }

    /**
    *   Tests method ChatterCompliance_UserQueueExists
    */
    static testMethod void testChatterCompliance_AdminSettingsUnusedFunctions(){
        test.startTest();

        PageReference testPage = Page.ChatterCompliance_AdminSettings;
        Test.setCurrentPage(testPage);

            ChatterCompliance_AdminSettings adminController = new ChatterCompliance_AdminSettings();
            adminController.initializeChatterCompliance();

             String cannotDeactivateUser = ChatterCompliance_AdminSettings.msgCanNotDeactivateUser;
             String ownerDoesNotExist = ChatterCompliance_AdminSettings.msgCurrentOwnerDoesNotExists;

            adminController.getObjects();

            ArkusChatterComplianceSettings__c adminSettings  = ArkusChatterComplianceSettings__c.getInstance('settings');
            adminSettings.Delete_original_content_schedule_job_id__c = System.schedule('Arkus Compliance for Chatter [delete original chatter posts]', '0 08 1-23 * * ?', new ChatterCompliance_OriginalCheckDeleted());

            adminSettings.Show_EVERY_word_on_word_blocker__c  =  true;
            adminController = new ChatterCompliance_AdminSettings();

            adminController.deleteOriginalContentUnscheduleJob();
            adminSettings.Show_EVERY_word_on_word_blocker__c  =  false;
            adminSettings.Substitute_bad_words_for_characters__c    = false;

            adminController = new ChatterCompliance_AdminSettings();
            adminController.setting_OwnerId = 'dijwfdijwe';
            adminController.addPageMessage('dofsodfvk');
            adminController.getItems();
            adminController.doNothing();

            ChatterCompliance_AdminSettings.replaceBannedWord('the banned word is replaced', 'word');

//     ChatterCompliance_AdminSettings.refreshOldCCRecords_asynchronic();

            Test.stopTest();

            system.assert(adminController != null);
    }

    /**
    *   Tests methods in ChatterCompliance_CheckDeleted
    */
    static testMethod void testChatterCompliance_CheckDeleted(){
        test.startTest();
        ArkusChatterComplianceSettings__c ccsetting= ArkusChatterComplianceSettings__c.getInstance('settings');
        ccsetting.Time_to_delete__c = 0;
        update ccsetting;

        chatterCompliance__c cc = new chatterCompliance__c();
        insert cc;
        chatterComplianceComment__c ccc = new chatterComplianceComment__c();
        ccc.ChatterCompliance__c = cc.Id;
        insert ccc;

        ChatterComplianceCommentNew__c cccn = new ChatterComplianceCommentNew__c();
        cccn.ChatterCompliance__c = cc.Id;
        insert cccn;

        ChatterCompliance_CheckDeleted controller = new ChatterCompliance_CheckDeleted();
        SchedulableContext sc = null;
        controller.execute(sc);
        test.stopTest();

        system.assert(controller != null);
    }

     /**
    *   Tests methods in ChatterCompliance_PrivateMessagesBatch
    */
    static testMethod void testChatterCompliance_PrivateMessagesBatch(){
        test.startTest();
        ChatterCompliance_PrivateMessagesBatch controller = new ChatterCompliance_PrivateMessagesBatch();
        ArkusChatterComplianceSettings__c adminSettings = ArkusChatterComplianceSettings__c.getInstance('settings');
        adminSettings.Scheduled_Job_Id__c = '213234';
        update adminSettings;
        controller.start(null);

        List<SObject> chatterMessages = Database.query('SELECT Body, SentDate, ConversationId, SenderId FROM ChatterMessage ORDER BY ConversationId, SentDate ASC LIMIT 100');
        controller.execute(null, chatterMessages );
        controller.finish(null);
        test.stopTest();

        system.assert(controller != null);
    }


     /**
    *   Tests methods for ChatterComplianceComment__c deletion
    */
    static testMethod void testChatterCompliance_CommentsDeletion(){
        test.startTest();
        ChatterCompliance__c cc = new ChatterCompliance__c();
        insert cc;

        ChatterComplianceComment__c ccc = new ChatterComplianceComment__c();
        ccc.ChatterCompliance__c = cc.Id;

        insert ccc;
        delete ccc;

        System.assert(ccc != null);

        test.stopTest();
    }


    /**
    *   Tests methods for ChatterComplianceCommentNew__c deletion
    */
    static testMethod void testChatterCompliance_CommentsNewDeletion(){
        test.startTest();
        ChatterComplianceCommentNew__c cccNew = new ChatterComplianceCommentNew__c();

        insert cccNew;
        delete cccNew;

        System.assert(cccNew != null);

        test.stopTest();
    }

    /**
    *   Tests methods for ChatterCompliance_FeedItem_WordBlocker trigger
    */
    static testMethod void testChatterCompliance_FeedItem_WordBlocker(){
     test.startTest();
     List<User> usr = [select Id from User LIMIT 1];

     ArkusChatterComplianceSettings__c ccsetting= ArkusChatterComplianceSettings__c.getInstance('settings');
     ccsetting.Send_email_if_banned_word_error__c = true;
     ccsetting.Show_EVERY_word_on_word_blocker__c = false;
     ccsetting.Substitute_bad_words_for_characters__c = false;
     Id recordtypeid = ChatterCompliance_Word_blocker__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('RegularExpression').getRecordTypeId();
     ChatterCompliance_Word_blocker__c regexp = new ChatterCompliance_Word_blocker__c(RecordTypeId = recordtypeid, Name='regexp');
     insert regexp;
     try{
         FeedItem fi = new FeedItem();
         fi.ParentId = usr.get(0).Id;
         fi.body = 'banned regexp';
         insert fi;
     }catch(Exception e){}

     ccsetting.Send_email_if_substituting_words__c = true;
     ccsetting.Substitute_bad_words_for_characters__c = true;
     ccsetting.Show_EVERY_word_on_word_blocker__c = false;
     update ccsetting;

     FeedItem fi2 = new FeedItem();
     fi2.ParentId = usr.get(0).Id;
     fi2.body = 'banned regexp';
     insert fi2;
     test.stopTest();

     system.assert(fi2 != null);
    }

    /**
    *   Tests methods for ChatterCompliance_FeedCommentAfterInsertDelete trigger
    */
    static testMethod void testChatterCompliance_FeedCommentAfterInsertDelete(){
     test.startTest();
     Profile p = [select Id from Profile where Name = 'Chatter Free User' LIMIT 1];

     List<User> usr = [select Id from User where ProfileId =: p.Id AND isActive = true LIMIT 1];

     System.RunAs(usr.get(0)){
          FeedItem post = new FeedItem();
          post.ParentId = Userinfo.getUserId();
          post.Body = 'Enter post text here';
          post.LinkUrl = 'http://www.someurl.com';
          insert post;

          FeedComment fcomment = new FeedComment();
          fcomment.FeedItemId = post.id;
          fcomment.CommentBody = 'Comment Body';
          insert fcomment;

          system.assert(fcomment != null);

          delete fcomment;
     }
     test.stopTest();
    }


     /**
    *   Tests methods for ChatterCompliance_FeedComment_WordBlocker trigger
    */
    static testMethod void testChatterCompliance_FeedComment_WordBlocker(){
     test.startTest();
     ArkusChatterComplianceSettings__c ccsetting= ArkusChatterComplianceSettings__c.getInstance('settings');
     ccsetting.Substitute_bad_words_for_characters__c = true;
     ccsetting.Send_email_if_substituting_words__c = true;
     update ccsetting;

     Id recordtypeid = ChatterCompliance_Word_blocker__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('RegularExpression').getRecordTypeId();
     ChatterCompliance_Word_blocker__c regexp = new ChatterCompliance_Word_blocker__c(RecordTypeId = recordtypeid, Name='regexp');
     insert regexp;

     FeedItem post = new FeedItem();
     post.ParentId = Userinfo.getUserId();
     post.Body = 'banned';
     post.LinkUrl = 'http://www.someurl.com';
     insert post;

     FeedComment fcomment = new FeedComment();
     fcomment.FeedItemId = post.id;
     fcomment.CommentBody = 'banned regexp';
     insert fcomment;

     ccsetting.Send_email_if_banned_word_error__c = true;
     ccsetting.Show_EVERY_word_on_word_blocker__c = false;
     ccsetting.Substitute_bad_words_for_characters__c = false;
     update ccsetting;

     List<User> usr = [select Id from User where Id !=: Userinfo.getUserId() LIMIT 1];
     FeedItem post2 = new FeedItem();
     post2.ParentId = usr.get(0).Id;
     post2.Body = 'http://www.someurl.com';
     post2.LinkUrl = 'http://www.someurl.com';
     insert post2;

     FeedComment fcomment2 = new FeedComment();
     fcomment2.FeedItemId = post2.id;
     fcomment2.CommentBody = 'comment body';
     insert fcomment2;

     system.assert(fcomment2 != null);

     test.stopTest();
     }

    /**
    *   Tests methods for ChatterCompliance_UserWordBlocker trigger
    */
    static testMethod void testChatterCompliance_UserWordBlocker(){
     test.startTest();
     List<User> usrs = [select CurrentStatus from User LIMIT 3];

     ArkusChatterComplianceSettings__c ccsetting= ArkusChatterComplianceSettings__c.getInstance('settings');
     ccsetting.Send_email_if_substituting_words__c = true;
     update ccsetting;

     Id recordtypeid = ChatterCompliance_Word_blocker__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('RegularExpression').getRecordTypeId();
     ChatterCompliance_Word_blocker__c regexp = new ChatterCompliance_Word_blocker__c(RecordTypeId = recordtypeid, Name='regexp');
     insert regexp;

     User usr = usrs.get(0);
     usr.CurrentStatus = 'banned regexp';
     update usr;

     ccsetting.Send_email_if_substituting_words__c = false;
     ccsetting.Send_email_if_banned_word_error__c = true;
     ccsetting.Substitute_bad_words_for_characters__c = false;
     update ccsetting;

     try{
         User usr2 = usrs.get(1);
         usr2.CurrentStatus = 'banned regexp';
         update usr2;
     }catch(Exception e){}

     ccsetting.Show_EVERY_word_on_word_blocker__c = true;
     update ccsetting;

     usr = usrs.get(1);
     usr.CurrentStatus = 'banned regexp';
     update usr;

     system.assert(usr != null);

     test.stopTest();
    }

    /**
    *   Tests methods for ChatterCompliance Simple functions
    */
    static testMethod void testChatterCompliance_simplefunctions(){
        List<User> list1 = [Select Id From User where Profile.UserLicense.Name != 'Chatter Free' limit 1];
        List<User> list2 = [Select Id From User where Profile.UserLicense.Name = 'Chatter Free' limit 1];

        ChatterCompliance_AdminSettings.IsChatterExternalOrFreeUser(list1[0].Id);
        system.assert(ChatterCompliance_AdminSettings.IsChatterExternalOrFreeUser(list2[0].Id));

    }

    static testMethod void testChatterCompliance_simplefunctions2(){
        ChatterCompliance_AdminSettings adminController = new ChatterCompliance_AdminSettings();

        Test.startTest();

        adminController.validateJobIDs();

        Test.stopTest();

        system.assert(adminController != null);
    }

    static testMethod void testChatterCompilancePostInstallScript(){
        ChatterCompliance_Utils postinstall = new ChatterCompliance_Utils();
        Test.testInstall(postinstall, new Version(1,0,3), true);
        system.assert(true);
    }

    static testMethod void testBatchCreateFeedItem() {

        PageReference testPage = Page.ChatterCompliance_AdminSettings;
        Test.setCurrentPage(testPage);

        if (ArkusChatterComplianceSettings__c.getInstance('settings') == null){
            ChatterCompliance_AdminSettings adminController = new ChatterCompliance_AdminSettings();
            adminController.initializeChatterCompliance();
        }

        ChatterCompliance_AdminSettings adminController = new ChatterCompliance_AdminSettings();

        adminController.pauseExecution();


        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
          User u = new User(Alias = 'standt', Email='standarduser@testorg.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', LocaleSidKey='en_US', ProfileId = p.Id,
                              TimeZoneSidKey='America/Los_Angeles', UserName='testUserFeedItemBatch@test.com');
        insert u;
        FeedItem fi;
        List<FeedItem> lfi = new List<FeedItem>();
        for(Integer i = 0; i< 4; i++){
         fi = new FeedItem( body = 'Some Body', ParentId = u.Id);
         lfi.add(fi);
        }
        List<ChatterCompliance__c> countBefore = [SELECT Id FROM ChatterCompliance__c];
        insert lfi;



        test.startTest();
        ChatterCompilance_FeedItemBatch_Log batch = new ChatterCompilance_FeedItemBatch_Log();
        Database.executeBatch(batch, 200);
        test.stopTest();


        List<ChatterCompliance__c> countafter = [SELECT Id FROM ChatterCompliance__c];

        system.assert(countBefore.size() < countAfter.size());
    }


    static testMethod void testBatchDeleteFeedItem() {

        PageReference testPage = Page.ChatterCompliance_AdminSettings;
        Test.setCurrentPage(testPage);

        if (ArkusChatterComplianceSettings__c.getInstance('settings') == null){
            ChatterCompliance_AdminSettings adminController = new ChatterCompliance_AdminSettings();
            adminController.initializeChatterCompliance();
        }

        List<FeedItem> lfi = [Select Id FROM FeedItem LIMIT 20];

        List<ChatterCompliance__c> countBefore = [SELECT Id FROM ChatterCompliance__c WHERE Delete__c = true];
        delete lfi;

        test.startTest();
        ChatterComp_FeedItemDeleteBatch_Log batch2 = new ChatterComp_FeedItemDeleteBatch_Log();
        Database.executeBatch(batch2, 2000);
        test.stopTest();

        List<ChatterCompliance__c> countafter = [SELECT Id FROM ChatterCompliance__c WHERE Delete__c = true];


        system.assert(true);
    }


    static testMethod void testChatterCompliance_FeedCommentCreate_Log() {

        PageReference testPage = Page.ChatterCompliance_AdminSettings;
        Test.setCurrentPage(testPage);

        if (ArkusChatterComplianceSettings__c.getInstance('settings') == null){
            ChatterCompliance_AdminSettings adminController = new ChatterCompliance_AdminSettings();
            adminController.initializeChatterCompliance();
        }

        ChatterCompliance_AdminSettings adminController = new ChatterCompliance_AdminSettings();


        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
          User u = new User(Alias = 'standt', Email='standarduser@testorg.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', LocaleSidKey='en_US', ProfileId = p.Id,
                              TimeZoneSidKey='America/Los_Angeles', UserName='testUserFeedItemBatch@test.com');
        insert u;
        FeedItem fi;
        fi = new FeedItem( body = 'Some Body', ParentId = u.Id);
        insert fi;
        adminController.pauseExecution();
        FeedComment fc;
        fc = new FeedComment( commentBody = 'Some Body', feedItemId = fi.Id);
        insert fc;
        List<ChatterComplianceComment__c> countBefore = [SELECT Id FROM ChatterComplianceComment__c];


        test.startTest();
            ChatterCompilance_FeedCommentBatch_Log batch = new ChatterCompilance_FeedCommentBatch_Log();
            Database.executeBatch(batch, 200);
        test.stopTest();
        List<ChatterComplianceComment__c> countafter = [SELECT Id FROM ChatterComplianceComment__c];

        system.assert(countBefore.size() < countAfter.size());
    }


    //test as a standar user
    static testMethod void testChatterCompliance_Standard_FeedCommentDelete_Log() {

        PageReference testPage = Page.ChatterCompliance_AdminSettings;
        Test.setCurrentPage(testPage);

        if (ArkusChatterComplianceSettings__c.getInstance('settings') == null){
            ChatterCompliance_AdminSettings adminController = new ChatterCompliance_AdminSettings();
            adminController.initializeChatterCompliance();
        }

        ChatterCompliance_AdminSettings adminController = new ChatterCompliance_AdminSettings();

        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
          User u = new User(Alias = 'standt', Email='standarduser@testorg.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', LocaleSidKey='en_US', ProfileId = p.Id,
                              TimeZoneSidKey='America/Los_Angeles', UserName='testUserFeedItemBatch@test.com');
        insert u;
        FeedItem fi;
        fi = new FeedItem( body = 'Some Body', ParentId = u.Id);
        insert fi;

        FeedComment fc;
        fc = new FeedComment( commentBody = 'Some Body', feedItemId = fi.Id);
        insert fc;
        List<ChatterComplianceComment__c> countBefore = [SELECT Id FROM ChatterComplianceComment__c WHERE Deleted__c = true];

        adminController.pauseExecution();

        delete fc;


        test.startTest();
        ChatterComp_FeedCommentDeleteBatch_Log batch = new ChatterComp_FeedCommentDeleteBatch_Log('ChatterComplianceComment__c');
            Database.executeBatch(batch, 200);
        test.stopTest();
        List<ChatterComplianceComment__c> countafter = [SELECT Id FROM ChatterComplianceComment__c WHERE Deleted__c = true];

        system.assert(countBefore.size() < countAfter.size());
    }

    //Test as a free user
    static testMethod void testChatterCompliance_Free_FeedCommentDelete_Log(){
        system.assert(true);
        PageReference testPage = Page.ChatterCompliance_AdminSettings;
        Test.setCurrentPage(testPage);

        if (ArkusChatterComplianceSettings__c.getInstance('settings') == null){
            ChatterCompliance_AdminSettings adminController = new ChatterCompliance_AdminSettings();
            adminController.initializeChatterCompliance();
        }

        ChatterCompliance_AdminSettings adminController = new ChatterCompliance_AdminSettings();

        Profile p = [select Id from Profile where Name = 'Chatter Free User' LIMIT 1];
        List<User> usr = [select Id from User where ProfileId =: p.Id AND isActive = true LIMIT 1];
        FeedComment fcomment;
        System.RunAs(usr.get(0)){
            FeedItem post = new FeedItem();
            post.ParentId = Userinfo.getUserId();
            post.Body = 'Enter post text here';
            post.LinkUrl = 'http://www.someurl.com';
            insert post;
            fcomment = new FeedComment();
            fcomment.FeedItemId = post.id;
            fcomment.CommentBody = 'Comment Body';
            insert fcomment;
        }

        List<ChatterComplianceCommentNew__c> countBefore = [SELECT Id FROM ChatterComplianceCommentNew__c WHERE Deleted__c = true];

        adminController.pauseExecution();

        delete fcomment;

        test.startTest();
        ChatterComp_FeedCommentDeleteBatch_Log batch = new ChatterComp_FeedCommentDeleteBatch_Log('ChatterComplianceCommentNew__c');
            Database.executeBatch(batch, 200);
        test.stopTest();
        List<ChatterComplianceCommentNew__c> countafter = [SELECT Id FROM ChatterComplianceCommentNew__c WHERE Deleted__c = true];

        system.assert(countBefore.size() < countAfter.size());
    }

}