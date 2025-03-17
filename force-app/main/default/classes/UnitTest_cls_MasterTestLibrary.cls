@isTest
private class UnitTest_cls_MasterTestLibrary {

    @isTest
    static void myUnitTest() {

		UnitTest_Test_data.commitFPIApexSettings(true);
        Account acct = [SELECT Id FROM Account WHERE RecordType.Name = 'Respondent Master Account' LIMIT 1];

        //UnitTest_Test_data.commitFPIApexSettings();
        
        //Account acct = UnitTest_Test_Data.buildTestAccount('Respondent Master Account', UserInfo.getUserId());
        //insert acct;

        //FPI_AppSettings__c testAppSetting1 = UnitTest_Test_data.BuildFPI_AppSettings(acct.Id, 'ID_RespondentAccount');
        //insert testAppSetting1;
        
        //FPI_AppSettings__c testAppSetting3 = UnitTest_Test_data.BuildFPI_AppSettings_RecordTypeLookup('RT_ContactRespondentAdult', 'Adult-Respondent', 'Contact');
        FPI_AppSettings__c testAppSetting4 = UnitTest_Test_data.BuildFPI_AppSettings_RecordTypeLookup('RT_ContactRespondentChild', 'Child-Respondent', 'Contact');
        //insert testAppSetting3;
        insert testAppSetting4;
        System.debug('DC: FPI_AppSettings__c.getall().values(): ' + FPI_AppSettings__c.getall().values());

		Id rtId = UtilityMethods.RECORDTYPE_ID('Contact', 'Adult-Respondent');
        Contact conTest = new Contact(Lastname='Lastname',FirstName='firstname',email='me@you.com',birthdate=System.Today().addYears(-40),RecordTypeId=rtId);
        insert conTest;

        Household__c hhTest = new Household__c(MailingStreet__c='123 MyStreet',MailingPostalCode__c='12345');
        insert hhTest;

        Household_Contact__c hcTest = new Household_Contact__c(Household__c=hhTest.Id,Contact__c=conTest.Id);
        insert hcTest;

        Master_Test__c mtTest = new Master_Test__c();
        insert mtTest;

        Quota__c mqTest = new Quota__c(Related_Test__c=mtTest.Id, IsScheduleEnabled__c=true,Beacon_Condition__c='conditionsQuota',IsOpen__c=true);
        insert mqTest;

        Quota__c mqUpdate1 = new Quota__c(Related_Test__c=mtTest.Id, IsScheduleEnabled__c=false,Beacon_Condition__c='contactupdate1',
        									Screener_Update_Field__c='Description',Screener_Update_Value__c='test123',IsOpen__c=true);
        insert mqUpdate1;

        Quota__c mqUpdate2 = new Quota__c(Related_Test__c=mtTest.Id, IsScheduleEnabled__c=false,Beacon_Condition__c='contactupdate2',
        									Screener_Update_Field__c='Department', IsOpen__c=true);
        insert mqUpdate2;

        Session__c ssTest = new Session__c(Name='Test Session',Related_Test__c=mtTest.Id,Session_Start__c=System.Now(),Session_End__c=System.Now().addHours(1));
        insert ssTest;

        Session__c ssTestLinked = new Session__c(Name='Test Session Linked',Related_Test__c=mtTest.Id,Session_Start__c=System.Now(),Session_End__c=System.Now().addHours(1),Linked_Session__c=ssTest.Id);
        insert ssTestLinked;

        Session_Quota__c sqTest = new Session_Quota__c(Related_Session__c=ssTest.Id,Master_Quota__c=mqTest.Id, IsOpen__c=true);
        insert sqTest;

        Test_Respondent__c trTest = new Test_Respondent__c();
        trTest.Master_Test__c = mtTest.Id;
        trTest.Respondent__c = conTest.Id;
        trTest.Check_Amount__c = 29.00;
        insert trTest;

        Test_Respondent_Quota__c trqTest = new Test_Respondent_Quota__c();
        trqTest.Test_Respondent__c = trTest.Id;
        trqTest.Session_Quota__c = sqTest.Id;
        trqTest.IsQualified__c = true;
        trqTest.IsScheduled__c = true;
        insert trqTest;

        MasterTestLibrary.checkForOpenQuotaSet(trTest, ssTest);
        MasterTestLibrary.scheduleRespondentForSession(trTest, ssTest);
        MasterTestLibrary.scheduleLinkedSessions(trTest.Id, ssTest.Id);

        Set<Id> sessionIds = new Set<Id>();
        sessionIds.add(ssTest.Id);
        MasterTestLibrary.cancelRespondentFromSession(trTest, sessionIds, true);

        Set<Id> trIds = new Set<Id>();
        trIds.add(trTest.Id);
        MasterTestLibrary.computeQuotaReportingMetrics(trIds);

    }
}