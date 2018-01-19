/**
*   Chatter Compliance System (all classes, triggers and pages that start with ChatterCompliance)
*   @author     Arkus Dev Team
*/
public class ChatterCompliance_AdminSettings {

    private static final Pattern idPattern = Pattern.compile('[(A-Z)|(a-z)|(0-9)]*');
    public ArkusChatterComplianceSettings__c   adminSettings       { get; set; }
    public String                                        error               { get; set; }
    public String                                        daysError           { get; set; }
    public transient Boolean                             success             { get; set; }
    public Boolean                                       alreadyScheduled    { get; set; }
    public String                                        showIcon            { get; set; }
    public Boolean                                       hasSettingsFile     { get; set; }
    public String                                        ownerName           { get; set; }
    public transient String                              ownerError          { get; set; }
    public Boolean                                       alreadyPaused       { get; set; }
    public String                                        option              { get; set; }
    public Boolean                                       originalFeedItemDeletionAlreadyScheduled       { get; set; }
    public Boolean                                       messageToComplianceAlreadyScheduled            { get; set; }
    public boolean                                       privateMessajesAlreadyScheduled                { get; set; }
    public boolean                                       firstLoad           { get; set; }
    public boolean                                       BatchRunning        { get; set; }

    //Can be YESTERDAY or NOW minus one hour, depending if the job runs every day or every hour.

    private ArkusChatterComplianceSettings__c adminSettingsBackup { get; set; }
    private Id saveOwnerId;
    private static String ReplaceBannedWords = '* * * *';

    public static String msgCanNotDeactivateUser{
        get{
            return 'The User is the owner of the Compliance Locker records. You must select a new owner in Compliance Locker Settings before you can deactivate this User.';
        }
    }
    public static String msgCurrentOwnerDoesNotExists{
        get{
            return 'The owner of the Compliance Locker records is not available anymore. Please select a new owner in the Compliance Locker Settings page.';
        }
    }

    // ===
    private transient String selectedAction;
    public string setting_isPaused{get;set;}
    public string setting_OwnerId{get;set;}
    public string setting_OwnerName{get;set;}
    public string setting_emailAddr{get;set;}
    public string setting_emailSubject{get;set;}
    public transient string setting_errorEmailSubject{get;set;}
    public string setting_doNotKeepAttchaments{get;set;}
    public string setting_doNotCreateCC{get;set;}

    public string setting_wb_blockerType{get;set;}
    public transient string setting_errorOnErrorMsg{get;set;}
    public string setting_onErrorMsg{get;set;}

    public string setting_wb_sendEmailWhenBlockingBadWords{get;set;}
    public string setting_wb_sendEmailWhenDisplayingErrorMessage{get;set;}
    public string setting_wb_sendEmailWhenDisplayingBadWords{get;set;}

    public string setting_TimeToDeleteOriginalPost{get;set;}
    public transient string setting_errorTimeToDeleteOriginalPost{get;set;}

    public string setting_TimeToDeleteCC{get;set;}
    public transient string setting_errorTimeToDeleteCC{get;set;}

    public string setting_privateMessagesPeriodicity{get;set;}
    public transient string setting_errorPrivateMsgPeriodicity{get;set;}
    // ===

    private string tabId = null;


    public List<SelectOption> getObjects(){
        list<Selectoption> selectedTimeList = new List<Selectoption>();
        selectedTimeList.add(new Selectoption('EVERY DAY','Daily'));
        selectedTimeList.add(new Selectoption('EVERY HOUR','Hourly'));
        return selectedTimeList;
    }

    /**
    *   Constructor of the class
    *   Get the custom settings record
    */
    public ChatterCompliance_AdminSettings(){
        this.tabId = ApexPages.currentPage().getParameters().get('sfdc.tabName');

        ownerName = '';
        success = false;
        alreadyScheduled = false;
        alreadyPaused = false;
        originalFeedItemDeletionAlreadyScheduled        =   false;
        privateMessajesAlreadyScheduled = false;
        firstLoad = true;
        if(ArkusChatterComplianceSettings__c.getInstance('settings') != null){
            adminSettings  = ArkusChatterComplianceSettings__c.getInstance('settings');
            adminSettingsBackup = ArkusChatterComplianceSettings__c.getInstance('settings');

            this.reloadAdminSettings();

            saveOwnerId = adminSettingsBackup.ChatterCompliance_Owner__c;
            hasSettingsFile = true;
            ownerName = adminSettings.ChatterCompliance_Owner_Name__c;
            alreadyPaused = adminSettings.Chatter_Compliance_paused__c;

            if((adminSettings.PrivateMessagesJobID__c != null) && (adminSettings.PrivateMessagesJobID__c != '')){
                privateMessajesAlreadyScheduled = true;
            }

            if((adminSettings.Scheduled_Job_Id__c != null) && (adminSettings.Scheduled_Job_Id__c != '')){
                alreadyScheduled = true;
            }

            if((adminSettings.Delete_original_content_schedule_job_id__c != null) && (adminSettings.Delete_original_content_schedule_job_id__c != '')){
                originalFeedItemDeletionAlreadyScheduled = true;
            }

            if (adminSettings.Show_EVERY_word_on_word_blocker__c  ==  true){
                option  =   'adminSettings.Show_EVERY_word_on_word_blocker__c';
            }else if (adminSettings.Substitute_bad_words_for_characters__c    ==  true){
                option  =   'adminSettings.Substitute_bad_words_for_characters__c';
            }else {
                option  =   'Show error messajes';
            }


        }else{
            hasSettingsFile = false;
        }
    }

    /**
    *   Pauses the execution of Chatter Compliance
    */
    public PageReference pauseExecution(){

        this.selectedAction = 'chatter paused';

        return this.validateAndSaveAllSettings();

    }

    /**
    *   Resumes the execution of Chatter Compliance
    */
    public PageReference resumeExecution(){

        this.selectedAction = 'chatter resume';

        return this.validateAndSaveAllSettings();

    }

    /**
    *   Function to re-load the settings
    */
    private void reloadAdminSettings(){
        adminSettings = null;
        this.setting_isPaused = '';
        this.setting_OwnerId = '';
        this.setting_OwnerName = '';
        this.setting_emailAddr = '';
        this.setting_emailSubject = '';
        this.setting_errorEmailSubject = '';
        this.setting_doNotKeepAttchaments = '';
        this.setting_doNotCreateCC = '';
        this.setting_wb_blockerType = 'option_showErrorMessage';
        this.setting_onErrorMsg = '';
        this.setting_errorOnErrorMsg = '';
        this.setting_wb_sendEmailWhenBlockingBadWords = '';
        this.setting_wb_sendEmailWhenDisplayingErrorMessage = '';
        this.setting_wb_sendEmailWhenDisplayingBadWords = '';
        this.setting_TimeToDeleteCC = '';
        this.setting_errorTimeToDeleteCC = '';
        this.setting_TimeToDeleteOriginalPost = '';
        this.setting_errorTimeToDeleteOriginalPost = '';
        this.setting_privateMessagesPeriodicity = '';
        this.setting_errorPrivateMsgPeriodicity = '';
        if(ArkusChatterComplianceSettings__c.getInstance('settings') != null){
            adminSettings  = ArkusChatterComplianceSettings__c.getInstance('settings');

            this.setting_isPaused = adminSettings.Chatter_Compliance_paused__c ? 'true' : 'false';
            if(adminSettings.BatchApexId_Log__c != NULL || adminSettings.ScheduleJobId_Log__c != NULL){
                List<AsyncApexJob> laaj;
                List<CronTrigger> lct;
                boolean brunning = false;
                boolean jrunning = false;
                if(adminSettings.BatchApexId_Log__c != NULL){
                    laaj = [SELECT Id, Status  FROM AsyncApexJob WHERE Id =: adminSettings.BatchApexId_Log__c];
                    if(laaj.size()>0){
                        brunning = laaj[0].Status != 'Aborted' && laaj[0].Status != 'Completed' && laaj[0].Status != 'Failed';
                    }
                }
                if(adminSettings.ScheduleJobId_Log__c != NULL){
                    lct = [SELECT Id, State FROM CronTrigger WHERE Id =: adminSettings.ScheduleJobId_Log__c];
                    if(lct.size()>0){
                        jrunning = lct[0].State != 'DELETED' && lct[0].State != 'ERROR';
                    }
                }
                this.BatchRunning = brunning || jrunning;
            }
            else{
                this.BatchRunning = false;

            }

            this.setting_OwnerId = adminSettings.ChatterCompliance_Owner__c;
            this.setting_OwnerName = adminSettings.ChatterCompliance_Owner_Name__c;
            this.setting_emailAddr = adminSettings.ChatterCompliance_Email__c;
            this.setting_emailSubject = adminSettings.selectedEmailSubject__c;
            this.setting_doNotKeepAttchaments = adminSettings.Do_not_keep_any_attachments__c ? 'true' : 'false';
            this.setting_doNotCreateCC = adminSettings.Do_NOT_create_the_chatter_compliance_rec__c ? 'true' : 'false';

            if(adminSettings.Show_EVERY_word_on_word_blocker__c == true){
                this.setting_wb_blockerType = 'option_showEveryWord';
            }else if(adminSettings.Substitute_bad_words_for_characters__c == true){
                this.setting_wb_blockerType = 'option_replaceWithCharacters';
            }else if(adminSettings.WordBlocker_ShowAnErrorMessage__c == true){
                this.setting_wb_blockerType = 'option_showErrorMessage';
            }else{
                this.setting_wb_blockerType = 'option_showEveryWord';
            }
            this.setting_onErrorMsg = adminSettings.Message_to_show_on_error__c;

            this.setting_wb_sendEmailWhenBlockingBadWords = adminSettings.Send_email_if_substituting_words__c ? 'true' : 'false';
            this.setting_wb_sendEmailWhenDisplayingBadWords = adminSettings.Send_email_if_showing_banned_words__c ? 'true' : 'false';
            this.setting_wb_sendEmailWhenDisplayingErrorMessage = adminSettings.Send_email_if_banned_word_error__c ? 'true' : 'false';

            this.setting_TimeToDeleteOriginalPost = adminSettings.Time_to_delete_original_records__c != null ? Integer.valueOf(adminSettings.Time_to_delete_original_records__c) + '' : '30';
            if(adminSettings.Delete_original_content_schedule_job_id__c != null && adminSettings.Delete_original_content_schedule_job_id__c != ''){
                originalFeedItemDeletionAlreadyScheduled = true;
            }else{originalFeedItemDeletionAlreadyScheduled = false;}

            this.setting_TimeToDeleteCC = adminSettings.Time_to_delete__c != null ? Integer.valueOf(adminSettings.Time_to_delete__c) + '' : '30';
            if(adminSettings.Scheduled_Job_Id__c != null && adminSettings.Scheduled_Job_Id__c != ''){
               alreadyScheduled = true;
            }else{alreadyScheduled = false;}

            this.setting_privateMessagesPeriodicity = adminSettings.PrivateMessagesJobPeriodicity__c != null && adminSettings.PrivateMessagesJobPeriodicity__c != '' ? adminSettings.PrivateMessagesJobPeriodicity__c : 'EVERY DAY';
            if(adminSettings.PrivateMessagesJobID__c != null && adminSettings.PrivateMessagesJobID__c != ''){
               privateMessajesAlreadyScheduled = true;
            }else{privateMessajesAlreadyScheduled = false;}

        }

    }

    /**
    *   Save the values for the custom setting record
    */
    public PageReference save(){
        Integer limitResult = 9500;
        if(Limits.getDmlRows() > 490){
            limitResult = Limits.getLimitDmlRows() - Limits.getDmlRows() - 100;
            if(limitResult < 0) limitResult = 0;
        }
        List<ChatterCompliance__c> lst = new List<ChatterCompliance__c>([Select id from ChatterCompliance__c limit :limitResult ]);

        for(ChatterCompliance__c cc : lst){
            cc.ownerId = adminSettings.ChatterCompliance_Owner__c;
        }

        if(validateNumber()){

            boolean ownerSuccess = false;
            try{
                if(!lst.isEmpty()){
                    update lst;
                }else{
                    ChatterCompliance__c testCC = new ChatterCompliance__c();
                    testCC.ownerId = adminSettings.ChatterCompliance_Owner__c;
                    upsert testCC;

                    delete testCC;
                }
                ownerSuccess = true;
            }catch(Exception e){
                 ownerError = 'Invalid User - you must select a User/Queue that permissions to own a Chatter Compliance record';
                 success = false;
                 showIcon = '';
                 this.adminSettings.ChatterCompliance_Owner_Name__c = this.adminSettingsBackup.ChatterCompliance_Owner_Name__c;
                 this.adminSettings.ChatterCompliance_Owner__c = saveOwnerId;
                 this.adminSettings.ChatterCompliance_Email__c = this.adminSettingsBackup.ChatterCompliance_Email__c;
                 return null;
            }

            if(ownerSuccess){
                // update name of the owner to show
                if(adminSettings.ChatterCompliance_Owner__c == Userinfo.getUserId()){
                    ownerName = Userinfo.getName();
                }else{
                    List<User> uList = [ SELECT u.Name FROM User u WHERE u.Id =: adminSettings.ChatterCompliance_Owner__c ];
                    if(!uList.isEmpty()){
                        ownerName = uList.get(0).Name;
                    }else{
                        List<Group> qList = [ SELECT q.Name FROM Group q WHERE q.Id =: adminSettings.ChatterCompliance_Owner__c ];
                        if(!qList.isEmpty()){
                            ownerName = qList.get(0).Name;
                        }
                    }
                }

                ArkusChatterComplianceSettings__c tempAdminSettings  = ArkusChatterComplianceSettings__c.getInstance('settings');

                adminSettings.ChatterCompliance_Owner_Name__c = ownerName;

                if(Schema.sObjectType.ArkusChatterComplianceSettings__c.isUpdateable()){
                    update adminSettings;
                }

                saveOwnerId = this.adminSettings.ChatterCompliance_Owner__c;

                daysError = '';
                showIcon = '';
                success = true;
                ownerError = '';
                return null;
            }else{
                 ownerError = 'Invalid User/Queue - you must select a User/Queue with permissions to own a \'Chatter Compliance\' and \'Chatter Compliance Comment New\' records';
                 success = false;
                 showIcon = '';
                 this.adminSettings.ChatterCompliance_Owner_Name__c = this.adminSettingsBackup.ChatterCompliance_Owner_Name__c;
                 this.adminSettings.ChatterCompliance_Owner__c = saveOwnerId;
                 this.adminSettings.ChatterCompliance_Email__c = this.adminSettingsBackup.ChatterCompliance_Email__c;
            }
        }else{
             success = false;
             daysError = 'The number of days to retain records must be a positive integer number';
             this.adminSettings.Time_to_delete__c = this.adminSettingsBackup.Time_to_delete__c;
             return null;
        }

        return null;
    }

    /**
    *   Validate and Save all settings in a single function
    */
    public pageReference validateAndSaveAllSettings(){

        boolean ownerValid = this.validateOwnerSetting();

        boolean error = false;


        Integer daysRetainOriginal = this.validateNumberGeneric(this.setting_TimeToDeleteOriginalPost);
        if(daysRetainOriginal == null || daysRetainOriginal < 1){
            error = true;
            this.setting_errorTimeToDeleteOriginalPost = 'Enter a number greater than zero';
        }

        Integer daysRetainCC = this.validateNumberGeneric(this.setting_TimeToDeleteCC);
        if(daysRetainCC == null || daysRetainCC < 1){
            error = true;
            this.setting_errorTimeToDeleteCC = 'Enter a number greater than zero';
        }

        if(this.setting_emailAddr.trim().length() > 3 && this.setting_emailSubject.trim().length() < 2){
            error = true;
            this.setting_errorEmailSubject = 'Enter a subject';
        }

        if(setting_wb_blockerType == 'option_showErrorMessage' && (setting_onErrorMsg == null || setting_onErrorMsg.length() < 2)){
            error = true;
            this.setting_errorOnErrorMsg = 'Enter an error message to display to users.';
        }

        if(!ownerValid){
            this.reloadAdminSettings();
            error = true;
            ownerError = 'Invalid User/Queue - you must select a User/Queue with permissions to own a \'Chatter Compliance\' and \'Chatter Compliance Comment New\' records';
        }

        if(this.privateMessajesAlreadyScheduled == true
        && adminSettings.PrivateMessagesJobPeriodicity__c != this.setting_privateMessagesPeriodicity
        ){
            this.setting_privateMessagesPeriodicity = adminSettings.PrivateMessagesJobPeriodicity__c;
            error = true;
            this.setting_errorPrivateMsgPeriodicity = 'You must Unschedule the job before changing periodicity';
        }

        if(!error){
            // Save Settings:

            // Update Owner in CC records:
            if(this.setting_OwnerId != null
            && this.setting_OwnerId != ''
            && adminSettings.ChatterCompliance_Owner__c != this.setting_OwnerId
            ){
                Id oId = this.setting_OwnerId;
                Integer limitResult = 9500;
                if(Limits.getDmlRows() > 490){
                    limitResult = Limits.getLimitDmlRows() - Limits.getDmlRows() - 100;
                    if(limitResult < 0) limitResult = 0;
                }
                List<ChatterCompliance__c> lcc = [Select id from ChatterCompliance__c limit :limitResult];
                for(ChatterCompliance__c cc : lcc){
                    cc.OwnerId = oId;
                }
                update lcc;
                limitResult = Limits.getLimitDmlRows() - Limits.getDmlRows() - 100;
                if(limitResult < 0) limitResult = 0;
                List<ChatterComplianceCommentNew__c> lcccNew = [Select id from ChatterComplianceCommentNew__c limit :limitResult];
                for(ChatterComplianceCommentNew__c ccc : lcccNew){
                    ccc.OwnerId = oId;
                }
                update lcccNew;
            }
            // ----------------------------------

            adminSettings.ChatterCompliance_Owner__c = (Id)this.setting_OwnerId;
            List<User> lu = [SELECT Name FROM User WHERE Id = :this.setting_OwnerId limit 1];
            adminSettings.ChatterCompliance_Owner_Name__c = !lu.isEmpty() ? lu[0].Name : [SELECT Name FROM Group WHERE Id = :this.setting_OwnerId limit 1][0].Name;
            adminSettings.ChatterCompliance_Email__c = this.setting_emailAddr;
            adminSettings.selectedEmailSubject__c = this.setting_emailSubject;
            adminSettings.Do_not_keep_any_attachments__c = this.setting_doNotKeepAttchaments == 'true' ? true : false;
            adminSettings.Do_NOT_create_the_chatter_compliance_rec__c = this.setting_doNotCreateCC == 'true' ? true : false;

            adminSettings.Show_EVERY_word_on_word_blocker__c = false;
            adminSettings.Substitute_bad_words_for_characters__c = false;
            adminSettings.WordBlocker_ShowAnErrorMessage__c = false;
            if(setting_wb_blockerType == 'option_showEveryWord'){
                adminSettings.Show_EVERY_word_on_word_blocker__c = true;
            }else if(setting_wb_blockerType == 'option_replaceWithCharacters'){
                adminSettings.Substitute_bad_words_for_characters__c = true;
            }else if(setting_wb_blockerType == 'option_showErrorMessage'){
                adminSettings.WordBlocker_ShowAnErrorMessage__c = true;
            }else{
                adminSettings.Show_EVERY_word_on_word_blocker__c = true;
            }

            adminSettings.Message_to_show_on_error__c = this.setting_onErrorMsg;

            adminSettings.Send_email_if_substituting_words__c = this.setting_wb_sendEmailWhenBlockingBadWords == 'true' ? true : false;
            adminSettings.Send_email_if_showing_banned_words__c = this.setting_wb_sendEmailWhenDisplayingBadWords == 'true' ? true : false;
            adminSettings.Send_email_if_banned_word_error__c = this.setting_wb_sendEmailWhenDisplayingErrorMessage == 'true' ? true : false;

            adminSettings.Time_to_delete_original_records__c = daysRetainOriginal;

            adminSettings.Time_to_delete__c = daysRetainCC;

            adminSettings.PrivateMessagesJobPeriodicity__c = this.setting_privateMessagesPeriodicity;

            if(this.selectedAction == 'chatter paused'){
                adminSettings.Chatter_Compliance_paused__c = true;
            }else if(this.selectedAction == 'chatter resume'){
                adminSettings.Chatter_Compliance_paused__c = false;
            }

            String errorExceptionMsg = '';
            try{
                if(Schema.sObjectType.ArkusChatterComplianceSettings__c.isUpdateable()){
                    update adminSettings;
                }else{
                    error = true;
                    this.addPageMessage('You do not have permission to modify these settings');
                }
            }catch(Exception e){
                error = true;
                errorExceptionMsg = e.getMessage();
            }

            if(!error){

                // SAVE SCHEDULE JOBS DATA
                if(this.selectedAction == 'schedule job original schedule'){
                    try{
                        adminSettings.Delete_original_content_schedule_job_id__c =
                        System.schedule('Arkus Compliance for Chatter [delete original chatter posts]', '0 0 5 * * ?', new ChatterCompliance_OriginalCheckDeleted());
                    }catch(Exception e){
                        adminSettings.Delete_original_content_schedule_job_id__c = '';
                    }
                }else if(this.selectedAction == 'schedule job original unschedule'){
                    try{system.abortjob(adminSettings.Delete_original_content_schedule_job_id__c);
                    }catch(Exception e){}
                    try{ChatterCompliance_AdminSettings.deleteScheduleJob_asynchronic(adminSettings.Delete_original_content_schedule_job_id__c);
                    }catch(Exception e){}
                    adminSettings.Delete_original_content_schedule_job_id__c = '';

                }else if(this.selectedAction == 'schedule job cc schedule'){
                    try{
                        adminSettings.Scheduled_Job_Id__c =
                        System.schedule('Arkus Compliance for Chatter [delete compliance records]', '0 0 6 * * ?', new ChatterCompliance_CheckDeleted());
                    }catch(Exception e){
                        adminSettings.Scheduled_Job_Id__c = '';
                    }
                }else if(this.selectedAction == 'schedule job cc unschedule'){
                    try{system.abortjob(adminSettings.Scheduled_Job_Id__c);
                    }catch(Exception e){}
                    try{ChatterCompliance_AdminSettings.deleteScheduleJob_asynchronic(adminSettings.Scheduled_Job_Id__c);
                    }catch(Exception e){}
                    adminSettings.Scheduled_Job_Id__c = '';

                }else if(this.selectedAction == 'schedule job private messages schedule'){
                    try{
                        String cronTime = '';
                        if(adminSettings.PrivateMessagesJobPeriodicity__c == 'EVERY HOUR'){
                            cronTime = '0 18 * * * ?';
                        }else{
                            cronTime = '0 18 3 * * ?';
                        }
                        adminSettings.PrivateMessagesJobID__c =
                        System.schedule('Arkus Compliance for Chatter [clone private messages]', cronTime, new ChatterCompliance_MessageScheduleJob(this.setting_privateMessagesPeriodicity));
                    }catch(Exception e){
                        adminSettings.PrivateMessagesJobID__c = '';
                    }
                }else if(this.selectedAction == 'schedule job private messages unschedule'){
                    try{system.abortjob(adminSettings.PrivateMessagesJobID__c);
                    }catch(Exception e){}
                    try{ChatterCompliance_AdminSettings.deleteScheduleJob_asynchronic(adminSettings.PrivateMessagesJobID__c);
                    }catch(Exception e){}
                    adminSettings.PrivateMessagesJobID__c = '';

                }else if(this.selectedAction == 'schedule job LOG schedule'){
                    if(!this.BatchRunning){
                        ChatterCompilance_FeedItemBatch_Log batch = new ChatterCompilance_FeedItemBatch_Log();
                        adminSettings.BatchApexId_Log__c = Database.executeBatch(batch, 25);
                        adminSettings.ScheduleJobId_Log__c = '';
                    }
                }

                update adminSettings;
                // =========================

                success = true;
            }else{
                if(errorExceptionMsg.toLowerCase().indexOf('invalid email address') < 0) this.addPageMessage(errorExceptionMsg);
            }

            reloadAdminSettings();

        }else{
            this.addPageMessage('Invalid data, please check out the errors');
        }

        PageReference pr = ApexPages.currentPage();
        if(this.tabId != null && this.tabId != '' && this.tabId != 'null'){pr.getParameters().put('sfdc.tabName', this.tabId);}

        return null;

    }

    /**
    *   Creates AdminSettings file when it does not exist
    */
    public PageReference initializeChatterCompliance(){
        this.setting_OwnerId = Userinfo.getUserId();
        boolean ownerValid = this.validateOwnerSetting();
        if(!ownerValid){
            this.addPageMessage('You must have permission to own \'Chatter Compliance\' and \'Chatter Compliance Comment New\' records');
            return null;
        }
        if(ArkusChatterComplianceSettings__c.getInstance('settings') == null){
            if(Schema.sObjectType.ArkusChatterComplianceSettings__c.isCreateable()){
                // create "settings" custom setting
                adminSettings  = new ArkusChatterComplianceSettings__c();
                adminSettings.Name = 'settings';
                adminSettings.ChatterCompliance_Owner__c = Userinfo.getUserId();
                adminSettings.ChatterCompliance_Owner_Name__c = Userinfo.getName();
                insert adminSettings;
            }
        }
        PageReference pr = ApexPages.currentPage();
        pr = pr.setRedirect(true);
        return pr;
    }

    private boolean validateOwnerSetting(){
        List<ChatterCompliance__c> lst = new List<ChatterCompliance__c>([Select id from ChatterCompliance__c limit 10]);
        List<ChatterComplianceCommentNew__c> lstNew = new List<ChatterComplianceCommentNew__c>([Select id from ChatterComplianceCommentNew__c limit 10]);

        for(ChatterCompliance__c cc : lst){
            cc.ownerId = this.setting_OwnerId;
        }

        for(ChatterComplianceCommentNew__c cccNew : lstNew){
            cccNew.ownerId = this.setting_OwnerId;
        }

        boolean ownerSuccess = false;

        Savepoint sp = Database.setSavepoint();

        try{
            if(!lst.isEmpty()){
                update lst;
            }else{
                ChatterCompliance__c testCC = new ChatterCompliance__c();
                testCC.ownerId = this.setting_OwnerId;
                upsert testCC;

            }
            ownerSuccess = true;
        }catch(Exception e){}

        if(ownerSuccess == true){
            try{
                if(!lstNew.isEmpty()){
                    update lstNew;
                }else{
                    ChatterComplianceCommentNew__c testCC = new ChatterComplianceCommentNew__c();
                    testCC.ownerId = this.setting_OwnerId;
                    upsert testCC;
                }
                ownerSuccess = true;
            }catch(Exception e){
                ownerSuccess = false;
            }
        }

        Database.rollback(sp);

        return ownerSuccess;
    }

    /**
    *   Returns whether the number for the days is valid
    *   @return     true if the number is a positive integer, false otherwise
    */
    public Boolean validateNumber(){
        if((adminSettings.Time_to_delete__c < 1) ||
            (Integer.valueOf(adminSettings.Time_to_delete__c) > adminSettings.Time_to_delete__c) ||
            (Integer.valueOf(adminSettings.Time_to_delete__c) < adminSettings.Time_to_delete__c)){
            return false;
        }
        return true;
    }

    public Integer validateNumberGeneric(String num){
        try{
            if(num != null){
                num = num.trim();
            }
            if(num == null
            || (num == '')
            || (Integer.valueOf(num) + '' > num)
            || (Integer.valueOf(num) + '' < num)
            ){
                return null;
            }
        }catch(exception e){ return null; }
        return Integer.valueOf(num);
    }

    /**
    *   Cancels and redirects to the homepage
    */
    public PageReference cancel(){
        return new PageReference('/home/home.jsp');
    }

    /**
    *   Sends an email to the custom setting email address when a chatterCompliance object is created.
    *   @param lst      list of record of chatter compliance records
    */
    public static void sendEmails(List<ChatterCompliance__c> lst){
        String email = ArkusChatterComplianceSettings__c.getInstance('settings').ChatterCompliance_Email__c;
        String emailSubject = ArkusChatterComplianceSettings__c.getInstance('settings').selectedEmailSubject__c;
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        Map<id,Attachment> attchs = new Map<id,Attachment>();
        List<id> idLst = new List<id>();

        for(ChatterCompliance__c cc: lst){
            idLst.add(cc.id);
        }

        for(Attachment a : [Select id,body,name,parentId from Attachment where parentId in :idLst]){
            attchs.put(a.parentId,a);
        }

        // Add information in the email of the User who created the post:
        Set<Id> uIds = new Set<Id>();
        for(ChatterCompliance__c cc: lst){
            if(cc.User__c != null) uIds.add(cc.User__c);
        }
        Map<Id, User> usersMap = new Map<Id, User>([SELECT Name, Username, Email FROM User WHERE Id IN :uIds]);
        // ---------------

        if((email != null) && (email != '')){

            for(ChatterCompliance__c cc: lst){
                Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                Messaging.SingleEmailMessage mail = ChatterCompliance_AdminSettings.createEmail('New post: "',cc.PostContent__c,cc.Related_record_name__c,cc.Related_record__c,cc.Post_Created_Date__c,email, usersMap.get(cc.User__c));
                mail.setSubject(emailSubject);
                if(cc.Related_record_name__c == null) cc.Related_record_name__c = '';
                if(cc.PostContent__c == null) cc.PostContent__c = '';

                if(cc.Files_Attached__c == true){
                    if(attchs.get(cc.id) != null){
                        efa.setBody(attchs.get(cc.id).Body);
                        efa.setFileName(attchs.get(cc.id).Name);
                        mail.setFileAttachments(new Messaging.EmailFileAttachment[] {efa});
                    }
                }
                mails.add(mail);
            }
            try{
                if(!mails.isEmpty())Messaging.sendEmail(mails);
            }catch(Exception e){

            }
        }
    }

    /**
    *   Sends an email to the custom setting email address when a chatterCompliance object is created.
    *   @param lst      list of record of chatter compliance comments
    */
    public static void sendEmails(List<ChatterComplianceComment__c> lst){
        ChatterCompliance_AdminSettings.sendEmails(lst, null);
    }
    public static void sendEmails(List<ChatterComplianceComment__c> lst, List<FeedComment> commentsList){
        if(ArkusChatterComplianceSettings__c.getInstance('settings') != null){
            String email = ArkusChatterComplianceSettings__c.getInstance('settings').ChatterCompliance_Email__c;
            String emailSubject = ArkusChatterComplianceSettings__c.getInstance('settings').selectedEmailSubject__c;
            List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
            List<id> idLst = new List<id>();
            Map<id,Attachment> attchs = new Map<id,Attachment>();

            Set<Id> parentComplianceIDs = new Set<Id>();

            for(ChatterComplianceComment__c cc: lst){
                idLst.add(cc.id);
                parentComplianceIDs.add(cc.ChatterCompliance__c);
            }

            Map<Id, ChatterCompliance__c> mapParentCompliances =
                new Map<Id, ChatterCompliance__c>([SELECT PostContent__c, Related_record_name__c FROM ChatterCompliance__c WHERE Id IN: parentComplianceIDs]);

            // Add information in the email of the User who created the post:
            Map<Id, FeedComment> commentsMap = new Map<Id, FeedComment>();
            Map<Id, User> usersMap = null;
            if(commentsList != null){
                Set<Id> uIds = new Set<Id>();
                for(FeedComment fi: commentsList){
                    commentsMap.put(fi.Id, fi);
                    if(fi.CreatedById != null) uIds.add(fi.CreatedById);
                }
                usersMap = new Map<Id, User>([SELECT Name, Username, Email FROM User WHERE Id IN :uIds]);
            }
            // ---------------

          for(Attachment a : [Select id,body,name,parentId from Attachment where parentId in :idLst]){
                attchs.put(a.parentId,a);
            }
            if((email != null) && (email != '')){
                for(ChatterComplianceComment__c cc: lst){
                    Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                    User uAux = null;
                    if(commentsList != null){
                        if(cc.commentId_New__c != null
                        && commentsMap.get(cc.commentId_New__c) != null
                        && commentsMap.get(cc.commentId_New__c).CreatedById != null
                        ){
                            uAux = usersMap.get( commentsMap.get(cc.commentId_New__c).CreatedById );
                        }else if(cc.commentId__c != null
                        && commentsMap.get(cc.commentId__c) != null
                        && commentsMap.get(cc.commentId__c).CreatedById != null
                        ){
                            uAux = usersMap.get( commentsMap.get(cc.commentId__c).CreatedById );
                        }
                    }
                    Messaging.SingleEmailMessage mail = ChatterCompliance_AdminSettings.createEmail('New comment: "',cc.commentContent__c, mapParentCompliances.get(cc.ChatterCompliance__c) != null ? mapParentCompliances.get(cc.ChatterCompliance__c).Related_record_name__c : '' ,cc.ChatterCompliance__c,DateTime.now(),email, uAux);
                    mail.setSubject(emailSubject);
                    if(cc.Files_Attached__c==true){
                        if(attchs.get(cc.id) != null){
                            efa.setBody(attchs.get(cc.id).Body);
                            efa.setFileName(attchs.get(cc.id).Name);
                            mail.setFileAttachments(new Messaging.EmailFileAttachment[] {efa});
                        }
                    }
                    mails.add(mail);
                }
                try{
                     if(!mails.isEmpty()) Messaging.sendEmail(mails);
                }catch(Exception e){

                }
            }
        }
    }

    /**
    *   Sends an email to the custom setting email address when a chatterCompliance object is created.
    *   @param lst      list of record of chatter compliance comments
    */
    public static void sendEmails(List<ChatterComplianceCommentNew__c> lst){
        ChatterCompliance_AdminSettings.sendEmails(lst, null);
    }
    public static void sendEmails(List<ChatterComplianceCommentNew__c> lst, List<FeedComment> commentsList){
        if(ArkusChatterComplianceSettings__c.getInstance('settings') != null){
            String email = ArkusChatterComplianceSettings__c.getInstance('settings').ChatterCompliance_Email__c;
            String emailSubject = ArkusChatterComplianceSettings__c.getInstance('settings').selectedEmailSubject__c;
            List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
            List<id> idLst = new List<id>();
            Map<id,Attachment> attchs = new Map<id,Attachment>();

            Set<Id> parentComplianceIDs = new Set<Id>();

            for(ChatterComplianceCommentNew__c cc: lst){
                idLst.add(cc.id);
                parentComplianceIDs.add(cc.ChatterCompliance__c);
            }

            Map<Id, ChatterCompliance__c> mapParentCompliances =
                new Map<Id, ChatterCompliance__c>([SELECT PostContent__c, Related_record_name__c FROM ChatterCompliance__c WHERE Id IN: parentComplianceIDs]);

            // Add information in the email of the User who created the post:
            Map<Id, FeedComment> commentsMap = new Map<Id, FeedComment>();
            Map<Id, User> usersMap = null;
            if(commentsList != null){
                Set<Id> uIds = new Set<Id>();
                for(FeedComment fi: commentsList){
                    commentsMap.put(fi.Id, fi);
                    if(fi.CreatedById != null) uIds.add(fi.CreatedById);
                }
                usersMap = new Map<Id, User>([SELECT Name, Username, Email FROM User WHERE Id IN :uIds]);
            }
            // ---------------

            for(Attachment a : [Select id,body,name,parentId from Attachment where parentId in :idLst]){
                attchs.put(a.parentId,a);
            }

            if((email != null) && (email != '')){
                for(ChatterComplianceCommentNew__c cc: lst){
                    Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                    User uAux = null;
                    if(commentsList != null){
                        if(cc.commentId__c != null
                        && commentsMap.get(cc.commentId__c) != null
                        && commentsMap.get(cc.commentId__c).CreatedById != null
                        ){
                            uAux = usersMap.get( commentsMap.get(cc.commentId__c).CreatedById );
                        }
                    }
                    Messaging.SingleEmailMessage mail = ChatterCompliance_AdminSettings.createEmail('New comment: "',cc.commentContent__c, mapParentCompliances.get(cc.ChatterCompliance__c) != null ? mapParentCompliances.get(cc.ChatterCompliance__c).Related_record_name__c : '' ,cc.ChatterCompliance__c,DateTime.now(),email, uAux);
                    mail.setSubject(emailSubject);
                    if(cc.Files_Attached__c==true){
                        if(attchs.get(cc.id) != null){
                            efa.setBody(attchs.get(cc.id).Body);
                            efa.setFileName(attchs.get(cc.id).Name);
                            mail.setFileAttachments(new Messaging.EmailFileAttachment[] {efa});
                        }
                    }
                    mails.add(mail);

                }
                try{
                     if(!mails.isEmpty()) Messaging.sendEmail(mails);
                }catch(Exception e){

                }
            }
        }
    }

    /**
    *   Sends an email to the custom setting email address when a chatterCompliance object is created.
    *   @param lst      list of record of chatter compliance comments
    */
    public static void sendEmails(List<FeedComment> lst){
        if(ArkusChatterComplianceSettings__c.getInstance('settings') != null){
            String email = ArkusChatterComplianceSettings__c.getInstance('settings').ChatterCompliance_Email__c;
            String emailSubject = ArkusChatterComplianceSettings__c.getInstance('settings').selectedEmailSubject__c;
            List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
            List<id> idLst = new List<id>();
            Map<id,Attachment> attchs = new Map<id,Attachment>();

            List<Id> relatedRecord_ids = new List<Id>();

            Set<Id> uIds = new Set<Id>();

            for(FeedComment fc: lst){
                idLst.add(fc.id);
                if(fc.RelatedRecordId != null){relatedRecord_ids.add(fc.RelatedRecordId);}

                uIds.add(fc.CreatedById);
            }

            // Add information in the email of the User who created the post:
            Map<Id, User> usersMap = new Map<Id, User>([SELECT Name, Username, Email FROM User WHERE Id IN :uIds]);
            // ---------------

            map<ID,ContentVersion> contentVersionMap =
            new map<Id,ContentVersion>([select title, filetype, contentSize, VersionData from ContentVersion WHERE Id IN :relatedRecord_ids AND ContentSize < 5242880]);

            if((email != null) && (email != '')){
                for(FeedComment fc: lst){
                    Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                    Messaging.SingleEmailMessage mail = ChatterCompliance_AdminSettings.createEmail('New comment: "',fc.commentbody, '', '-no compliance-',DateTime.now(),email, usersMap.get(fc.CreatedById));
                    mail.setSubject(emailSubject);
                    if(contentVersionMap.get(fc.RelatedRecordId) != null){
                        efa.setBody(contentVersionMap.get(fc.RelatedRecordId).VersionData);
                        efa.setFileName(contentVersionMap.get(fc.RelatedRecordId).title + '.' + contentVersionMap.get(fc.RelatedRecordId).filetype.toLowerCase());
                        mail.setFileAttachments(new Messaging.EmailFileAttachment[] {efa});
                    }
                    mails.add(mail);
                }
                try{
                     if(!mails.isEmpty()) Messaging.sendEmail(mails);
                }catch(Exception e){

                }
            }
        }

    }

    /**
    *   Builds an email to a given address
    *   @param body             body of the email if it's html
    *   @param content          content of the email if it's plain text
    *   @param related          text of the post
    *   @param relatedId        id of the related record
    *   @param dDate            date to display
    *   @param toAddress        address to send the email
    *   @return                 message to send with the data entered
    */
    public static Messaging.SingleEmailMessage createEmail(String body,String content,String related,String relatedId,DateTime dDate,String toAddress){
        return ChatterCompliance_AdminSettings.createEmail(body, content, related, relatedId, dDate, toAddress, null);
    }
    public static Messaging.SingleEmailMessage createEmail(String body,String content,String related,String relatedId,DateTime dDate,String toAddress, User userWhoMadeThePost){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setBccSender(false);
        mail.setToAddresses(new List<String>{toAddress});
        mail.setUseSignature(false);
        mail.setSaveAsActivity(false);
        mail.setPlainTextBody(content);
        if(related == null) related = '';
        if(content == null) content = '';
        String extraUserInfo = '';
        if(userWhoMadeThePost != null){
            //extraUserInfo = 'User that did the post: ' + userWhoMadeThePost.Name + ' (' + userWhoMadeThePost.Id + ')<br />';
            extraUserInfo = 'Posting User Details<br />Name: ' + userWhoMadeThePost.Name + '<br />ID: ' + userWhoMadeThePost.Id + '<br />Username: ' + userWhoMadeThePost.Username + '<br />Email: ' + userWhoMadeThePost.Email + '<br />';
        }
        mail.setHtmlBody(body + content + '"    on ' + related + ' record (' + relatedId + ')<br />' + extraUserInfo + dDate);
        mail.setSubject('New chatter compliance');
        return mail;
    }

    /**
    *   Starts the sheduled job for deleting the old chatterCompliance records
    */
    public pageReference scheduleJob(){

        this.selectedAction = 'schedule job cc schedule';

        return this.validateAndSaveAllSettings();
    }

    /**
    *   Removes the sheduled job for deleting the old chatterCompliance records
    */
    public pageReference unscheduleJob(){

        this.selectedAction = 'schedule job cc unschedule';

        return this.validateAndSaveAllSettings();

    }

    /**
    *   Starts the sheduled job for cloning the private chatter messages
    */
    public pageReference scheduleMessageToCompliance(){

        this.selectedAction = 'schedule job private messages schedule';

        return this.validateAndSaveAllSettings();

    }

    /**
    *   Removes the sheduled job for cloning the private chatter messages
    */
    public pageReference unscheduleMessageToCompliance(){

        this.selectedAction = 'schedule job private messages unschedule';

        return this.validateAndSaveAllSettings();

    }

    /**
    *   Redirects to the Setup > Monitoring
    */
    public PageReference goToMonitoring(){
        return new PageReference('/'+ Schema.sObjectType.Crontrigger.getKeyPrefix());
    }

    /**
    *   Refresh old CC records, copy PostId__c in PostId_New__c
    */
    public static void refreshOldCCRecords(){
        try{
            List<ChatterCompliance__c> mapCCupdate = [SELECT Id FROM chatterCompliance__c WHERE PostId_New__c = null ORDER BY Post_Created_Date__c ASC LIMIT 10];
            //Check if it's necessary to run the @future method:
            if(!mapCCupdate.isEmpty()){
                ChatterCompliance_AdminSettings.refreshOldCCRecords_asynchronic();
            }
        }catch(Exception e){
            try{ChatterCompliance_AdminSettings.deleteOldCCRecords_asynchronic(1);}catch(Exception e2){}
        }

        try{
            List<ChatterComplianceComment__c> mapCCCupdate = [SELECT Id FROM chatterComplianceComment__c WHERE CommentId_New__c = null ORDER BY CreatedDate ASC LIMIT 10];
            //Check if it's necessary to run the @future method:
            if(!mapCCCupdate.isEmpty()){
                ChatterCompliance_AdminSettings.refreshOldCCRecords_asynchronic();
            }
        }catch(Exception e){
            try{ChatterCompliance_AdminSettings.deleteOldCCRecords_asynchronic(2);}catch(Exception e2){}
        }

    }

    /**
    *   ASYNCHRONIC call to refresh old CC records (copy PostId__c in PostId_New__c)
    */
    @future
    public static void refreshOldCCRecords_asynchronic(){
        try{
            List<ChatterCompliance__c> mapCCupdate = [SELECT PostId__c,PostId_New__c FROM chatterCompliance__c WHERE PostId_New__c = null ORDER BY Post_Created_Date__c DESC LIMIT 5000];
            if(mapCCupdate.size() > 0){
                for(ChatterCompliance__c c_c : mapCCupdate){
                    c_c.PostId_New__c = c_c.PostId__c;
                }
                update mapCCupdate;
            }
        }catch(Exception e){}

        if(Limits.getDMLRows() < 7000){
            try{
                List<ChatterComplianceComment__c> mapCCCupdate = [SELECT CommentId__c,CommentId_New__c FROM chatterComplianceComment__c WHERE CommentId_New__c = null ORDER BY CreatedDate DESC LIMIT 2500];
                if(mapCCCupdate.size() > 0){
                    for(ChatterComplianceComment__c c_cc : mapCCCupdate){
                        c_cc.CommentId_New__c = c_cc.CommentId__c;
                    }
                    update mapCCCupdate;
                }
            }catch(Exception e){}
        }
    }
    /**
    *   ASYNCHRONIC call to delete old CC records when having more than 100.000
    */
    @future
    public static void deleteOldCCRecords_asynchronic(Integer deleteType){
        // delete old chatterCompliance__c:
        if(deleteType == 1){
            try{
                delete [SELECT Id FROM chatterCompliance__c WHERE PostId_New__c = null ORDER BY Post_Created_Date__c ASC LIMIT 9900];
            }catch(Exception e){}
        }
        // delete old chatterComplianceComment__c:
        if(deleteType == 2){
            try{
                delete [SELECT Id FROM chatterComplianceComment__c WHERE CommentId_New__c = null ORDER BY CreatedDate ASC LIMIT 9900];
            }catch(Exception e){}
        }
    }

    /**
    *   ASYNCHRONIC call to delete a Job from the queue
    */
    @future
    public static void deleteScheduleJob_asynchronic(String jobId){
        try{
            System.abortJob(jobId);
        }catch(Exception e){}
    }

    /**
    *  check if the Id exist in salesforce
    */
    public static Boolean existId(String anId){
        //check if is a User Id
        List<User> user = [select Id from User where Id=:anId];
        if(user.isEmpty()){
            //check if is a Group Id
            List<Group> groups = [select Id from Group where Id=:anId];
            if(groups.isEmpty()){
                //is not an User Id and is not a Group Id
                return false;
            }
            else return true;
        }
        else return true;
    }


    public List<SelectOption> getItems() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('option_showEveryWord','Do not block any word'));
        options.add(new SelectOption('option_replaceWithCharacters','Replace banned words with characters'));
        options.add(new SelectOption('option_showErrorMessage','Show an error message'));

        return options;
    }

    /**
    *   Starts the sheduled job for deleting original chatter posts
    */
    public pageReference deleteOriginalContentScheduleJob(){

        this.selectedAction = 'schedule job original schedule';

        return this.validateAndSaveAllSettings();

    }

    /**
    *   Removes the sheduled job for deleting original chatter posts
    */
    public pageReference deleteOriginalContentUnscheduleJob(){

        this.selectedAction = 'schedule job original unschedule';

        return this.validateAndSaveAllSettings();

    }


    /**
    *   "DoNothing" function [ DO NOT DELETE ]
    */
    public pageReference doNothing(){
        // This function is used in the page as a dummy function to not submit
        // the form when the userd hits 'ENTER'
        return null;
    }


    /**
    *   Function to add "error messages" to the page
    */
    public void addPageMessage(String msg){
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, msg));
    }


    /**
    *   Function used by WordBlocker to replace banned words with characters
    */
    public static String replaceBannedWord(String originalSentence, String bannedWord){

        originalSentence = originalSentence.trim();

        string replaceBy = ReplaceBannedWords;

        //string chatterwords = originalSentence.toUpperCase();
        //string banned = bannedWord.toUpperCase();

        //string aux = originalSentence;
        //string result = '';
        //integer indexw = -1;

        /*while(chatterwords.indexOf(banned) > -1){
            indexw = chatterwords.indexOf(banned);

            result += aux.substring(0, indexw) + replaceBy;

            aux = aux.substring(indexw + banned.length());
            chatterwords = chatterwords.substring(indexw + banned.length());
        }

        String resultaux = result + aux;

        if (resultaux.length()>1000){
            resultaux = resultaux.substring(0,1000);
        }*/
        Matcher WordBlockerMatcher =  Pattern.compile('(?i)(?<=^|\\s)[\\d\\W_&&[^\\s]]*' +  bannedWord  + '[\\d\\W_&&[^\\s]]*(?=\\s|$|\\.)').matcher(originalSentence);
        /*Regular Expression: 
        (?i) : Case insensitive
        (?<=^|\\s) : words at the beginning or with a white space before without replacing the white space.
        [\\d\\W&&[^\\s]]* : the word can have any type of characters before o after but if it has it is not a white space ([^\\s]).
        (?=\\s|$|\\.) : the word must have a white space a dot or must be at the end of the sentence.
        */
        System.debug('########################## WORD');
        //return resultaux;
        return WordBlockermatcher.replaceAll(replaceBy);
    }

    public static String replaceBannedWordRegExp(String originalSentence, String bannedWord){

        string replaceBy = ReplaceBannedWords;
        System.debug('########################## REGULAR EXPRESION' + bannedWord + originalSentence + ' ' + originalSentence.replaceAll(bannedWord, replaceBy));
        return originalSentence.replaceAll(bannedWord, replaceBy);
    }


    /**
    *   Check if the already saved JobIDs are valid Jobs in the queue,
    *    if not, delete the JobId setting.
    */
    @future
    private static void validateJobIDs_asynch(){
        boolean updateSetting = false;
        ArkusChatterComplianceSettings__c ccsetting = null;
        try{
            ccsetting = ArkusChatterComplianceSettings__c.getInstance('settings');
        }catch(Exception e){ccsetting = null;}
        if(ccsetting != null){
            Map<string, Id> map_jobField_jobId = new Map<string, Id>();
            Set<Id> ids = new Set<Id>();

            if(ccsetting.Delete_original_content_schedule_job_id__c != null && ccsetting.Delete_original_content_schedule_job_id__c != ''){
                map_jobField_jobId.put(
                    'Delete_original_content_schedule_job_id__c',
                    ccsetting.Delete_original_content_schedule_job_id__c
                );
            }
            if(ccsetting.Scheduled_Job_Id__c != null && ccsetting.Scheduled_Job_Id__c != ''){
                map_jobField_jobId.put(
                    'Scheduled_Job_Id__c',
                    ccsetting.Scheduled_Job_Id__c
                );
            }
            if(ccsetting.PrivateMessagesJobID__c != null && ccsetting.PrivateMessagesJobID__c != ''){
                map_jobField_jobId.put(
                    'PrivateMessagesJobID__c',
                    ccsetting.PrivateMessagesJobID__c
                );
            }

            if(map_jobField_jobId.size() > 0){
                for(CronTrigger ct : [SELECT Id FROM CronTrigger WHERE Id IN :map_jobField_jobId.values()]){
                    ids.add(ct.Id);
                }
                for(String s : map_jobField_jobId.keySet()){
                    if(!ids.contains(map_jobField_jobId.get(s))){
                        ccsetting.put(s, null);
                        updateSetting = true;
                    }
                }
                if(updateSetting && Schema.sObjectType.ArkusChatterComplianceSettings__c.isUpdateable()){
                    update ccsetting;
                }
            }
        }


    }

    public void validateJobIDs(){
        try{
            ChatterCompliance_AdminSettings.validateJobIDs_asynch();
        }catch(Exception e){}
    }

    public static Boolean IsChatterExternalOrFreeUser(Id idUser){
        List<User> usrs = [select Profile.UserLicense.Name from User where Id =: idUser];
        if(!usrs.isEmpty()){
            if(usrs[0].Profile.UserLicense.Name == 'Chatter Free'
                ||
                usrs[0].Profile.UserLicense.Name == 'Chatter External'
            ){
                return true;
            }
            return false;
        }
        return false;
    }

    public static Map<Id, boolean> IsChatterExternalOrFreeUser(List<Id> idUser){
        List<User> usrs = [select Id, Profile.UserLicense.Name from User where Id IN: idUser];
        Map<Id, boolean> freeOrExternal = new Map<Id, boolean>();
        if(!usrs.isEmpty()){
            for(User u: usrs){
                if(u.Profile.UserLicense.Name == 'Chatter Free' || u.Profile.UserLicense.Name == 'Chatter External'){
                    freeOrExternal.put(u.Id, true);
                }
                else{
                    freeOrExternal.put(u.Id, false);
                }
            }
        }
        return freeOrExternal;
    }


     /**
    *   Map to share data between triggers:
    */
    public static Map<String, String> static_global_map{get;set;}
    public static Map<String, String> static_global_map2{get;set;}
    public static Map<String, String> static_global_map3{get;set;}


    public void scheduleBatch(){
        this.selectedAction = 'schedule job LOG schedule';

        /*ArkusChatterComplianceSettings__c Setting = ArkusChatterComplianceSettings__c.getInstance('settings');
        if(!this.BatchRunning){
            ChatterCompilance_FeedItemBatch_Log batch = new ChatterCompilance_FeedItemBatch_Log();
            Setting.BatchApexId_Log__c = Database.executeBatch(batch, 25);
        }
        update setting;
        this.reloadAdminSettings();*/

        this.validateAndSaveAllSettings();
    }

}